#!/home/th026106/.pyenv/versions/docker-ls-remote/bin/python

"""List images in a docker registry."""

from __future__ import annotations

import argparse
import dataclasses
import fnmatch
import getpass
import json
import logging
from base64 import b64decode
from functools import cache, cached_property
from netrc import netrc
from pathlib import Path
from typing import TYPE_CHECKING, Self

import requests

if TYPE_CHECKING:
    # if we can't b64decode an auth str, we use it unmodified
    Auth = requests.sessions._Auth | None

DEFAULT_REGISTRY_NAME = "registry-1.docker.io"

logger = logging.getLogger("docker-ls-remote")


def urljoin(head, *parts):
    """smash url path parts together"""
    parts = [part.strip("/") for part in parts]
    return "/".join([head] + parts)


@dataclasses.dataclass(frozen=True)
class Registry:
    """A dataclass representing a docker registry"""

    name: str
    proto: str = "https"

    @property
    def url(self) -> str:
        return f"{self.proto}://{self.name}"

    @property
    def is_default(self) -> bool:
        return self.name == DEFAULT_REGISTRY_NAME


@dataclasses.dataclass(frozen=True)
class Image:
    """A dataclass representing a docker image or a docker image pattern."""

    registry: Registry
    path: str
    tag: str | None = None

    @cached_property
    def name(self):
        if self.registry.is_default:
            name = self.path
        else:
            name = self.registry.name + "/" + self.path
        if self.tag:
            name += ":" + self.tag
        return name

    @cached_property
    def has_glob_path(self) -> bool:
        return bool(set("[]?*") ^ set(self.path))

    @classmethod
    def parse(cls, name: str) -> Self:
        match name.split("/"):
            case (path,) | ("library", path):
                host = DEFAULT_REGISTRY_NAME
                path = f"library/{path}"
            case (host, path):
                pass
            case (host, group, item):
                path = group + "/" + item
            case _:
                raise ValueError("invalid image name", name)

        path, _, tag = path.partition(":")
        return cls(Registry(host), path, tag or None)


class AuthManager:
    """A class to manage authentication information."""

    def __init__(self, default_auth: Auth = None, *, prompting: bool = True):
        """Initialize a new AuthManager."""
        self.default_auth: Auth = default_auth
        self.auth_map: dict[Registry | None, Auth] = {}

        self.prompting: bool = prompting

    def pick_auth(self, registry: Registry):
        auth = self.auth_map.get(registry)
        if not auth:
            auth = self._pick_auth(registry)
            self.auth_map[registry] = auth
        return auth

    def _pick_auth(self, registry: Registry) -> Auth:
        """Pick an authorization value based on user input, registry, and configuration."""

        if auth := self.check_docker_config(registry):
            logger.debug("Using credentials from docker config")
            return auth

        if netrc_match := netrc().authenticators(registry.name):
            logger.debug("Using credentials from netrc")
            lookup_username, _, lookup_password = netrc_match
            return lookup_username, lookup_password

        if self.prompting:
            logger.debug("Prompting for credentials")
            return self.prompt_for_creds()

        logger.debug("Proceeding without credentials")
        return None

    def check_docker_config(self, registry: Registry) -> Auth:
        config_auth = self.get_docker_config_auth()
        return config_auth.get(registry) if config_auth else None

    @staticmethod
    @cache
    def get_docker_config_auth(
        filename: str | Path | None = None,
    ) -> dict[Registry, Auth]:
        if not filename:
            filename = Path("~/.docker/config.json").expanduser()

        with open(filename) as fin:
            config_data = json.load(fin)

        if "auths" not in config_data:
            return {}

        config_dict = {}
        for host, hostdict in config_data["auths"].items():
            registry = Registry(host)
            raw_auth: str = hostdict.get("auth")
            auth: str | tuple[str, str] = raw_auth
            try:
                # undo http basic auth encoding so we can compare usernames later
                username, password = b64decode(auth).decode("utf-8").split(":", 1)
                auth = (username, password)
            except ValueError:
                pass
            config_dict[registry] = auth
        return config_dict

    @staticmethod
    def prompt_for_creds() -> tuple[str, str] | None:
        """Ask for a username & password"""
        user_guess = getpass.getuser()
        username = input("Username [%s]: " % user_guess) or user_guess
        password = getpass.getpass()
        if password:
            return username, password
        return None


def collect(
    patterns: list[str],
    auth_manager: AuthManager,
    *,
    tls_verify: bool = True,
) -> list[Image]:
    """Collect matching Image results."""
    conn_table: dict[Registry, Connection] = {}

    results = []
    for pattern in patterns:
        image = Image.parse(pattern)

        logger.info("Examining input: %s", pattern)
        # are there are glob characters in this image path?
        glob_pattern = bool(set("[]?*") & set(image.path))
        if glob_pattern and image.registry.is_default:
            # we can't access the catalog for `docker hub`, so we can't
            # do image path globbing
            logger.warning("Cannot glob image paths in default registry: %s", image)
            continue

        if not (conn := conn_table.get(image.registry)):
            conn = Connection(image.registry, auth_manager, tls_verify=tls_verify)
            conn_table[image.registry] = conn

        partials: list[Image]
        if glob_pattern:
            matches = fnmatch.filter(conn.catalog, image.path)
            partials = [Image(image.registry, match, image.tag) for match in matches]
        else:
            partials = [image]

        for image in partials:
            logger.info("Processing Image: %s", image)
            tags = conn.get_tags(image.path)
            results += [Image(image.registry, image.path, tag) for tag in tags]

    return results


def display_table(results: list[Image]):
    if not results:
        print("[!] No results")
        return

    table_rows = [(result.registry, result.path, result.tag) for result in results]
    table_columns = zip(*table_rows)
    column_widths = [max(len(str(part)) for part in column) for column in table_columns]
    for row in table_rows:
        # zip together row values and column widths into a tuple
        values_and_widths: tuple = sum(zip(row, column_widths), ())
        # pass that information into a cleverly constructed string formatting template
        print("{registry!s:{}} | {path!s:{}} | {tag!s:{}}".format(*values_and_widths))


def display_json(results: list[Image]):
    structure = [dataclasses.asdict(result) for result in results]
    print(json.dumps(structure, sort_keys=True, indent=2))


def display_list(results: list[Image]):
    if not results:
        print("[!] No results")
        return

    for result in results:
        print(result.name)


class Connection:
    def __init__(self, registry: Registry, auth_manager: AuthManager, tls_verify=True):
        self._registry = registry

        self._sesh = requests.Session()
        self._sesh.verify = tls_verify
        self._sesh.headers = {
            "Accept": "application/vnd.docker.distribution.manifest.v2+json, application/json",
            "User-Agent": "docker or something",
        }

        self._sesh.auth = auth_manager.pick_auth(registry)

    def _get_json(self, url) -> dict:
        return self._request("get", url).json()

    def _request(
        self, method: str, url: str, headers: dict = {}, check_status: bool = True
    ) -> requests.Response:
        resp = self._sesh.request(method, url, headers=headers)
        if check_status:
            resp.raise_for_status()
        return resp

    @cached_property
    def catalog(self):
        # this url is disabled on the global registry...
        url = urljoin(self._registry.url, "v2", "_catalog")
        logger.debug("Fetching catalog: %s", url)
        data = self._get_json(url)
        return data["repositories"]

    def get_tags(self, name):
        url = urljoin(self._registry.url, "v2", name, "tags", "list")
        logger.debug("Fetching tags: %s", url)
        data = self._get_json(url)
        return data["tags"]

    def get_manifest(self, name, tag):
        url = urljoin(self._registry.url, "v2", name, "manifests", tag)
        logger.debug("Fetching manifest: %s", url)
        data = self._get_json(url)
        return data


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "names",
        nargs="+",
        help="The name(s) of the repos to list. Accepts shell wildcards. (remember to quote them!)",
    )
    parser.add_argument(
        "-k", "--insecure", action="store_true", help="ignore TLS certificate errors"
    )
    parser.add_argument(
        "-v",
        "--verbose",
        default=0,
        action="count",
        help="be more verbose; may be repeated",
    )
    parser.add_argument(
        "-n",
        "--non-interactive",
        action="store_true",
        help="Run without user interaction",
    )

    display_group = parser.add_mutually_exclusive_group()
    display_group.add_argument(
        "-j",
        "--json",
        dest="display",
        action="store_const",
        const="json",
        help="output in json format",
    )
    display_group.add_argument(
        "-t",
        "--table",
        dest="display",
        action="store_const",
        const="table",
        help="output in ascii table format",
    )

    args = parser.parse_args()

    log_level = logging.WARNING - (args.verbose * 10)
    logging.basicConfig(
        level=max(log_level, logging.DEBUG),
        format="[%(asctime)s %(levelname)-8s] %(message)s",
    )

    try:
        auth_manager = AuthManager()

        results = collect(args.names, auth_manager, tls_verify=not args.insecure)

        if args.display == "json":
            display_json(results)
        elif args.display == "table":
            display_table(results)
        else:
            display_list(results)
    except (KeyboardInterrupt, BrokenPipeError):
        pass


if __name__ == "__main__":
    main()
