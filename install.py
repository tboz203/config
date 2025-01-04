#!/usr/bin/env python3
"""Install configuration files."""

from __future__ import annotations

import argparse
import logging
import os
import shutil
from pathlib import Path
from typing import Callable

ROOT = Path(__file__).absolute().parent
DESCRIPTION = __doc__
logging.basicConfig(level=logging.INFO, format="%(levelname)s: %(message)s")
logger = logging.getLogger(__name__)


def remove_path(path: Path) -> None:
    """Remove the file or directory at the given path."""
    if path.is_dir() and not path.is_symlink():
        shutil.rmtree(path)
    else:
        path.unlink()


def preserve_path(path: Path, max_backup_count: int = 10) -> None:
    """Rename the file or directory at the given path as a backup."""
    suffixes = [".bak"] + [f".{i}.bak" for i in range(1, max_backup_count)]
    for suffix in suffixes:
        new_path = path.with_suffix(path.suffix + suffix)
        if new_path.exists():
            continue

        path.replace(new_path)
        return

    raise RuntimeError("Too many backups!", path)


def relative_to(path: Path, target: Path) -> Path:
    """Return the relative path from `path` to `target`."""
    ancestor = Path(os.path.commonpath([path, target]))
    backtrack = "../" * len(path.relative_to(ancestor).parents)
    return Path(backtrack + str(target.relative_to(ancestor)))


def link_files(
    source_dir: Path,
    dest_dir: Path,
    relative_links: bool,
    preserve_existing: bool,
    dryrun: bool,
    transformer: Callable[[Path], Path] | None = None,
):
    """Link files from one directory to another."""
    if not source_dir.exists():
        logger.warning("Skipping missing source directory: %s", source_dir)
        return

    if not dest_dir.exists():
        logger.info("creating %s", dest_dir)
        if not dryrun:
            dest_dir.mkdir(parents=True)

    for path in source_dir.iterdir():
        if relative_links:
            target = relative_to(dest_dir, path)
        else:
            target = path

        link = dest_dir.joinpath(path.name)
        if transformer:
            link = transformer(link)

        if link.is_symlink() and link.readlink() == target:
            if dryrun:
                logger.info("would skip %s", link)
            else:
                logger.info("skipping %s", path)
            continue

        if link.exists() or link.is_symlink():
            if preserve_existing:
                if dryrun:
                    logger.info("would preserve %s", link)
                else:
                    logger.info("preserving %s", link)
                    preserve_path(link)
            else:
                if dryrun:
                    logger.info("would destroy %s", link)
                else:
                    logger.info("destroying %s", link)
                    remove_path(link)

        logger.info("%s -> %s", link, target)
        if not dryrun:
            link.symlink_to(target)


def config_install(
    config_root: os.PathLike,
    homedir: os.PathLike,
    configdir: os.PathLike,
    sshdir: os.PathLike,
    relative_links: bool = True,
    preserve_existing: bool = False,
    dryrun: bool = True,
) -> None:
    """
    Install config files.

    :param config_root: root of the `config` project
    :param homedir: the home directory to install to
    :param configdir: the config directory to install to
    :param sshdir: the ssh directory to install to
    :param relative: create relative symlinks, defaults to True
    :param preserve: rename existing files to `*.bak`, defaults to False
    :param dryrun: look but don't touch, defaults to False
    """

    config_root = Path(config_root).absolute()
    homedir = Path(homedir).absolute()
    configdir = Path(configdir).absolute()
    sshdir = Path(sshdir).absolute()
    settings: dict = {
        "relative_links": relative_links,
        "preserve_existing": preserve_existing,
        "dryrun": dryrun,
    }

    # first dotfiles
    link_files(
        config_root.joinpath("dotfiles"),
        homedir,
        **settings,
        transformer=(lambda p: p.with_name("." + p.name)),
    )

    # then configfiles
    link_files(config_root.joinpath("configfiles"), configdir, **settings)

    # then sshfiles
    link_files(config_root.joinpath("sshfiles"), sshdir, **settings)


def main() -> None:
    parser = argparse.ArgumentParser(description=DESCRIPTION)
    parser.add_argument(
        "-r",
        "--relative-links",
        "--relative",
        action="store_true",
        help="make symlinks relative",
    )
    parser.add_argument(
        "-p",
        "--preserve-existing",
        "--preserve",
        action="store_true",
        help="preserve existing files as backups",
    )
    parser.add_argument(
        "-d",
        "--dryrun",
        "--dry-run",
        action="store_true",
        help="make no changes; describe what actions would be taken",
    )
    args = parser.parse_args()

    config_install(
        config_root=ROOT,
        homedir=Path.home(),
        configdir=Path.home().joinpath(".config"),
        sshdir=Path.home().joinpath(".ssh"),
        relative_links=args.relative_links,
        preserve_existing=args.preserve_existing,
        dryrun=args.dryrun,
    )


if __name__ == "__main__":
    main()
