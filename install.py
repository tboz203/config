#!/usr/bin/env python3
"""Install configuration files."""

from __future__ import annotations

import argparse
import logging
import os
import shutil
from collections.abc import Callable, Sequence
from dataclasses import dataclass
from pathlib import Path

ROOT = Path(__file__).absolute().parent
DESCRIPTION = __doc__
logging.basicConfig(level=logging.INFO, format="%(levelname)s: %(message)s")
logger = logging.getLogger(__name__)


@dataclass
class Settings:
    """A dataclass for holding script settings."""

    # the root of the config source
    config_root: Path = Path(ROOT)
    # the home directory to install to
    home_dir: Path = Path.home()
    # the config directory to install to
    config_dir: Path = Path.home() / '.config'
    # the ssh directory to install to
    ssh_dir: Path = Path.home() / '.ssh'
    # whether to perform any actions
    dry_run: bool = False
    # whether to create relative symbolic links
    relative_links: bool = False
    # whether to create hard links
    hard_links: bool = False
    # what to do for file conflicts
    on_conflict: Literal["skip", "rename", "overwrite"] = "skip"


def remove_path(path: Path) -> None:
    """Remove the file or directory at the given path."""
    if path.is_dir() and not path.is_symlink():
        shutil.rmtree(path)
    else:
        path.unlink()


def rename_path(path: Path, max_backup_count: int = 10) -> None:
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
    settings: Settings,
    transformer: Callable[[Path], Path] | None = None,
):
    """Link files from one directory to another."""
    if not source_dir.exists():
        logger.warning("Skipping missing source directory: %s", source_dir)
        return

    if not dest_dir.exists():
        if settings.dry_run:
            logger.info("would create %s", dest_dir)
        else:
            logger.info("creating %s", dest_dir)
            dest_dir.mkdir(parents=True)

    for path in source_dir.iterdir():
        if settings.relative_links:
            target = relative_to(dest_dir, path)
        else:
            target = path

        link = dest_dir.joinpath(path.name)
        if transformer:
            link = transformer(link)

        if (link.exists() and link.samefile(target)) or (link.is_symlink() and link.readlink() == target):
            # same file!
            if settings.dry_run:
                logger.info("would skip %s", link)
            else:
                logger.info("skipping %s", path)
            continue

        if link.exists() or link.is_symlink():
            # conflict!
            if settings.on_conflict == "overwrite":
                if settings.dry_run:
                    logger.info("would overwrite %s", link)
                else:
                    logger.info("removing %s", link)
                    remove_path(link)
            elif settings.on_conflict == "rename":
                if settings.dry_run:
                    logger.info("would rename %s", link)
                else:
                    logger.info("renaming %s", link)
                    rename_path(link)
            else:
                if settings.dry_run:
                    logger.info("would skip %s", link)
                else:
                    logger.info("skipping %s", link)
                continue

        logger.info("%s -> %s", link, target)
        if not settings.dry_run:
            if settings.hard_links:
                if path.is_dir():
                    raise NotImplementedError("we don't have that yet :(", link, target)
                link.hardlink_to(target)
            else:
                link.symlink_to(target)


def config_install(settings: Settings) -> None:
    """Install all my config files."""

    # first dotfiles
    link_files(
        settings.config_root / "dotfiles",
        settings.home_dir,
        settings,
        transformer=(lambda p: p.with_name("." + p.name)),
    )

    # then configfiles
    link_files(settings.config_root / "configfiles", settings.config_dir, settings)

    # then sshfiles
    link_files(settings.config_root / "sshfiles", settings.ssh_dir, settings)


def get_settings() -> Settings:
    
    parser = argparse.ArgumentParser(description=DESCRIPTION)
    parser.add_argument(
        "-R",
        "--relative-links",
        action="store_true",
        help="make symlinks relative",
    )
    parser.add_argument(
        "-D",
        "--dry-run",
        action="store_true",
        help="make no changes; describe what actions would be taken",
    )
    parser.add_argument(
        "-H",
        "--hard-links",
        action="store_true",
        help="use hard links instead of symbolic links",
    )

    conflict_group = parser.add_mutually_exclusive_group()
    conflict_group.add_argument(
        "-r",
        "--rename-conflicts",
        action="store_const",
        dest="conflict",
        const="rename",
        help="rename conflicting files as backups",
    )
    conflict_group.add_argument(
        "-s",
        "--skip-conflicts",
        action="store_const",
        dest="conflict",
        const="skip",
        help="skip conflicting files",
    )
    conflict_group.add_argument(
        "-o",
        "--overwrite-conflicts",
        action="store_const",
        dest="conflict",
        const="overwrite",
    )

    args = parser.parse_args()

    return Settings(
        relative_links=args.relative_links,
        dry_run=args.dry_run,
        hard_links=args.hard_links,
        on_conflict=args.conflict
    )


if __name__ == "__main__":
    settings = get_settings()
    config_install(settings)
