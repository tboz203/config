#!/usr/local/bin/python3

"""List images in a docker registry."""

import argparse
import fnmatch
import getpass
import json
from base64 import b64decode
from dataclasses import dataclass
from datetime import datetime
from functools import cached_property
from netrc import netrc
from pathlib import Path
from typing import Optional, cast

import requests

# both are optional, but we won't have a password without a username
Creds = tuple[str, Optional[str]] | tuple[None, None]
# if we can't b64decode an auth str, we use it unmodified
Auth = str | Creds | None

# DEFAULT_REGISTRY = 'https://gntbuild.cgifederal.com:5000'
# DEFAULT_REGISTRY = 'https://artifacts.cgifederal.com:30100'
# DEFAULT_REGISTRY = 'https://docker-approved.artpro.digitalglobe.com:443'
# DEFAULT_REGISTRY = 'https://docker.artpro.digitalglobe.com:443'
DEFAULT_REGISTRY = "registry-1.docker.io"


def urljoin(head, *parts):
    """smash url parts together"""
    url = head
    for part in parts:
        url = url.rstrip("/") + "/" + part.lstrip("/")
    return url


@dataclass
class Registry:
    """A dataclass representing a docker registry"""

    name: str
    proto: str = "https"

    @property
    def url(self) -> str:
        return f"{self.proto}://{self.name}"

    @property
    def is_default(self) -> bool:
        return self.name == DEFAULT_REGISTRY


@dataclass
class Image:
    """A dataclass representing a docker image name. may contain wildcards"""
    registry: Registry
    path: str
    tag: Optional[str] = None

    @property
    def name(self):
        if self.registry.is_default:
            name = self.path
        else:
            name = self.registry.name + '/' + self.path
        if self.tag:
            name += ':' + self.tag
        return name

@dataclass
class Result(Image):
    """A dataclass representing a docker image. may contain extra metadata,
    may *not* contain wildcards"""
    digest: Optional[str] = None
    created: Optional[datetime] = None


def pick_credentials(registry: Registry, user_string: Optional[str] = None) -> Auth:
    """pick credentials based on user input, registry, and configuration."""

    # we need to pick a registry, a username, and a password. we may be given
    # any of these on the command line; we may be able to collect these from
    # docker config, and/or netrc; we can use a default for the registry and
    # we can guess that our process username matches our docker username; and
    # as a final recourse, we can ask the user directly.
    #
    # should also be noted; credentials are not always required?
    #
    # additionally, we may decide that we want to write whatever information we
    # gather back *into* docker config
    #
    # if they give us all three, give them right back
    # elif they give us username & password (registry is missing),
    # ... do we try to look up a matching registry from docker config??
    # no, i think that's a bad idea.
    #
    #  host
    #   |  username
    #   v   v  password
    # +---+---+---+
    # | X | X | X |  everything given to us!
    # | X | X | _ |  docker config; netrc; prompt
    # | X | _ | X |  impossible
    # | X | _ | _ |  docker config; netrc; empty creds
    # | _ | X | X |  ???
    # | _ | X | _ |  ???
    # | _ | _ | X |  impossible
    # | _ | _ | _ |  docker config; ???
    #
    # so in general:
    # 1) if we don't have a host ...
    #    i think we should always have a host, as a requirement. either an
    #    explicit one in an image name, or an implicit `docker hub` one.
    # 2) try to match what we have to docker config
    # 3) if we have a host; try to match it to netrc
    # 4) if we have a username without a password, prompt the user

    username, password = try_split_creds(user_string)

    if username and password:
        # we've got something from CLI args
        return username, password

    if auth := _check_docker_config(registry, username, password):
        # found a match in the docker config
        return auth

    if netrc_match := netrc().authenticators(registry.name):
        # found a netrc match based on hostname...
        lookup_username, _, lookup_password = netrc_match
        if username in (lookup_username, None) and password in (lookup_password, None):
            # and either our username/password matched, or we didn't have them
            return lookup_username, lookup_password

    if username:
        # got a username but no password; ask user directly
        return prompt_for_creds(username)

    # if not host and not username:
    #     if config_auth:
    #         # take the first pair listed
    #         registry, auth = list(config_auth.items())[0]
    #         return registry, auth

    # raise RuntimeError("can't determine registry & credentials")
    return None


def _check_docker_config( registry: Registry, username: Optional[str], password: Optional[str]) -> Auth:
    config_auth = _get_docker_config_auth()

    if not config_auth:
        return None

    if password and not username:
        raise ValueError("nonsense")

    match config_auth.get(registry):
        case str() as auth if not (username or password):
            # lookup found single auth string, no username or password provided
            return auth
        case lookup_username, lookup_password:
            if username in (lookup_username, None) and password in (lookup_password, None):
                # either we matched the lookup, or we had nothing to check against
                return cast(Auth, (lookup_username, lookup_password))
        case _:
            return None


def _get_docker_config_auth(filename=None) -> dict[Registry, Auth]:
    if not filename:
        filename = Path("~/.docker/config.json").expanduser()

    with open(filename) as fin:
        config_data = json.load(fin)

    if "auth" not in config_data:
        return {}

    # return {f'https://{host}': hostdict['auth'] for host, hostdict in config_data.get('auth', {}).items()}
    config_dict = {}
    for host, hostdict in config_data["auth"]:
        registry = Registry(host)
        auth = hostdict.get("auth")
        try:
            # undo http basic auth encoding so we can compare usernames later
            auth = b64decode(auth).decode("utf-8").split(":", 1)
        except ValueError:
            pass
        config_dict[registry] = auth
    return config_dict


def try_split_creds(user_string: Optional[str]) -> Creds:
    """Attempt to split a `user[:password]`string."""
    if not user_string:
        return (None, None)
    user, password = user_string.split(":", 1)
    return user, password


def prompt_for_creds(user_guess: Optional[str] = None) -> tuple[str, str]:
    """Ask the user for a username & password"""
    if not user_guess:
        user_guess = getpass.getuser()
    username = input("Username [%s]: " % user_guess) or user_guess
    password = getpass.getpass()
    if not password:
        raise ValueError("No password supplied")

    return username, password


def parse_image_name(name) -> Image:
    match name.split('/'):
        case str():
            host = DEFAULT_REGISTRY
            path = f'library/{name}'
        case str(), str():
            host = DEFAULT_REGISTRY
            path = name
        case host, group, item:
            path = group + '/' + item
        case _:
            raise ValueError("invalid image name", name)

    path, _, tag = path.partition(':')
    return Image(Registry(host), path, tag or None)


def collect(patterns: list[Image], user_string: Optional[str], verbose: bool = False, tls_verify=True) -> list[Result]:

    conn_table: dict[Registry, Connection] = {}

    for pattern in patterns:

        # are there are glob characters in this image path?
        glob_pattern = bool(set('[]?*') ^ set(pattern.path))
        if glob_pattern and pattern.registry.is_default:
            # we can't access the catalog for `docker hub`, so we can't
            # do image path globbing
            print(f"Cannot glob image paths in default registry: {pattern}")
            continue

        if not (conn := conn_table.get(pattern.registry)):
            conn = Connection(pattern.registry, user_string, tls_verify=tls_verify)
            conn_table[pattern.registry] = conn

        partials: list[Image]
        if glob_pattern:
            matches = fnmatch.filter(conn.catalog, pattern.path)
            partials = [Image(pattern.registry, match, pattern.tag) for match in matches]
        else:
            partials = [pattern]

        for pattern in partials:
            print('gotta get tags & maybe "verbose"')

    return []

    con = Connection(registry, credentials, tls_verify=tls_verify)

    catalog = con.get_catalog()
    matches = list()
    for pattern in names:
        matches += fnmatch.filter(catalog, pattern)

    lines = []
    for repo in matches:
        try:
            tags = con.get_tags(repo)
        except OSError as exc:
            print((exc, exc.filename))
            tags = []
        if tags:
            pairs = []
            if tag_pattern:
                tags = fnmatch.filter(tags, tag_pattern)

            if fast:
                for tag in tags:
                    lines.append((repo, tag, None, None))
            else:
                for tag in tags:
                    created = con.get_created_date(repo, tag)
                    if not created:
                        created = None
                    else:
                        created = str(created.replace(microsecond=0))
                    try:
                        digest = con.get_digest(repo, tag)
                    except (NotImplementedError, OSError):
                        digest = None
                    lines.append((repo, tag, digest, created))
        else:
            lines.append((repo, None, None, None))

    return lines


def display_verbose(lines):
    # don't look directly at this function or you may go insane
    column_widths = [max(len(str(x)) for x in l) for l in zip(*lines)]
    for repo, tag, digest, created in lines:
        print(
            "{repo!s:{}} | {tag!s:{}} | {digest!s:{}} | {created!s:{}}".format(
                *column_widths, repo=repo, tag=tag, digest=digest, created=created
            )
        )


def display_json(lines):
    structure = [
        {"repo": repo, "tag": tag, "digest": digest, "created": created} for repo, tag, digest, created in lines
    ]
    print(json.dumps(structure, sort_keys=True, indent=2))


def display_images(lines):
    for repo, tag, _, _ in lines:
        if repo and tag:
            print(f"{repo}:{tag}")


class Connection:
    DATEFORMAT = "%Y-%m-%dT%H:%M:%S.%f"

    def __init__(self, registry: Registry, user_string: Optional[str], retries=3, tls_verify=True):
        self._registry = registry

        self._sesh = requests.Session()
        self._sesh.verify = tls_verify
        self._sesh.headers = {
            "Accept": "application/vnd.docker.distribution.manifest.v2+json, application/json",
            "User-Agent": "docker or something",
        }

        self._sesh.auth = pick_credentials(registry, user_string)  # type: ignore

        self._retries = retries

    def _get_json(self, url):
        return self._request("get", url).json()

    def _delete(self, url):
        self._request("delete", url)

    def _request(self, method, url, headers={}, check_status=True):
        last_exc = None
        for i in range(self._retries):
            resp = None
            try:
                resp = self._sesh.request(method, url, headers=headers)
                if check_status:
                    resp.raise_for_status()
                return resp
            except requests.HTTPError as exc:
                last_exc = exc
                if exc.response.status_code == 401:
                    print("Request failed: Unauthorized")
                    # don't prompt for credentials if we're not trying again
                    if i != (self._retries - 1):
                        self._sesh.auth = prompt_for_creds()
                else:
                    raise
            except OSError as exc:
                last_exc = exc
                print(f"request: caught exception (attempt {i}): {exc}")

        raise RuntimeError("too many attempts") from last_exc

    @cached_property
    def catalog(self):
        # this url is disabled on the global registry...
        url = urljoin(self._registry.url, "v2/_catalog")
        data = self._get_json(url)
        return data["repositories"]

    def get_tags(self, name):
        url = urljoin(self._registry.url, "v2/%s/tags/list" % name)
        data = self._get_json(url)
        return data["tags"]

    def get_manifest(self, name, tag):
        url = urljoin(self._registry.url, "v2/%s/manifests/%s" % (name, tag))
        data = self._get_json(url)
        return data

    # def get_digest(self, name, tag):
    #     manifest = self.get_manifest(name, tag)
    #     blob = manifest['history'][0].get('v1Compatibility', None)
    #     if not blob:
    #         raise NotImplementedError("Can't do that :)")
    #     data = json.loads(blob)
    #     return data['id']

    # def get_created_date(self, name, tag):
    #     try:
    #         manifest = self.get_manifest(name, tag)
    #     except OSError:
    #         return None
    #     nested = manifest['history'][0]['v1Compatibility']
    #     nested = json.loads(nested)
    #     # cutting off the last few digits b/c python can't natively handle nanoseconds
    #     timestamp = nested['created'][:-4]
    #     return datetime.strptime(timestamp, self.DATEFORMAT)

    def get_blob(self, name, digest):
        url = urljoin(self._registry.url, f"v2/{name}/blobs/{digest}")
        data = self._get_json(url)
        return data

    def get_digest(self, name, tag):
        return self.get_manifest(name, tag).get("config", {}).get("digest", "?????")

    def get_created_date(self, name, tag):
        try:
            digest = self.get_digest(name, tag)
        except (RuntimeError, OSError):
            return None
        blob = self.get_blob(name, digest)
        if "created" not in blob:
            return None
        # cutting off the last few digits b/c python can't natively handle nanoseconds
        timestamp = blob["created"][:-4]
        return datetime.strptime(timestamp, self.DATEFORMAT)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "names", nargs="+", help="The name(s) of the repos to list. Accepts shell wildcards. (remember to quote them!)"
    )
    parser.add_argument("-u", "--user", help="user[:password] - credentials for the given repository")
    parser.add_argument("-k", "--insecure", action="store_true", help="ignore TLS certificate errors")

    parser.add_argument("-j", "--json", action="store_true", help="output in json format")
    parser.add_argument("-v", "--verbose", action="store_true", help="lookup & display more details")

    args = parser.parse_args()

    try:
        results = collect(args.names, args.verbose, not args.insecure)

        if args.json:
            display_json(results)
        elif args.verbose:
            display_verbose(results)
        else:
            display_images(results)
    except (KeyboardInterrupt, BrokenPipeError):
        pass


if __name__ == "__main__":
    main()
