#!/usr/bin/env python3
"""
Install configuration files.
"""

from __future__ import annotations

import argparse
import logging
import os
import shutil
from collections.abc import Callable
from pathlib import Path
from typing import Literal

try:
    from _winapi import CreateJunction  # type: ignore
except ImportError:

    def CreateJunction(*args, **kwargs):
        del args, kwargs
        raise NotImplementedError("CreateJunction not available")


def is_junction(path: Path | str) -> bool:
    if os.path.islink(path) or not os.path.isdir(path):
        # junctions return `False` for `islink` and `True` for `isdir`
        return False
    try:
        # junctions are processed by `readlink` without error (usually)
        os.readlink(path)
        return True
    except OSError:
        return False


ROOT = Path(__file__).absolute().parent
DESCRIPTION = __doc__
logging.basicConfig(level=logging.INFO, format="%(levelname)s: %(message)s")
logger = logging.getLogger(__name__)


class Installer:
    """
    A class to manage installing my config.
    """

    def __init__(
        self,
        config_root: Path = Path(ROOT),
        home_dir: Path = Path.home(),
        config_dir: Path = Path.home() / ".config",
        ssh_dir: Path = Path.home() / ".ssh",
        dry_run: bool = False,
        symbolic_links: bool | None = None,
        relative_links: bool | None = None,
        on_conflict: Literal["skip", "rename", "overwrite"] = "skip",
    ):
        """
        Create a new Installer.

        `config_root` should be the root of a "config" directory (such as this git repository)
        `home_dir` should be your home directory
        `config_dir` should be your config directory (e.g. `~/.config`)
        `ssh_dir` should be your ssh directory (e.g `~/.ssh`)

        `dry_run` determines whether actions are performed, or just displayed
        `symbolic_links` determines whether to use hard links or symbolic links (default is platform specific
        `relative_links` determines whether or not created symbolic links are relative or absolute
        `preserve` determines whether existing files are removed or preserved (renamed)
        """

        if symbolic_links is None:
            symbolic_links = os.name != "nt"

        self.config_root = config_root
        self.home_dir = home_dir
        self.config_dir = config_dir
        self.ssh_dir = ssh_dir

        self.dry_run = dry_run
        self.symbolic_links = symbolic_links
        self.relative_links = relative_links
        self.on_conflict = on_conflict

    def install(self):
        """Install links from each managed directory."""
        self._install_links(
            self.config_root / "dotfiles", self.home_dir, transformer=self._tr_dotfile
        )
        self._install_links(self.config_root / "configfiles", self.config_dir)
        self._install_links(self.config_root / "sshfiles", self.ssh_dir)

    def _install_links(
        self,
        source_dir: Path,
        dest_dir: Path,
        transformer: Callable[[Path], Path] | None = None,
    ):
        """Link files from one directory to another."""
        if not source_dir.exists():
            logger.warning("Skipping missing source directory: %s", source_dir)
            return

        if not dest_dir.exists():
            if self.dry_run:
                logger.info("would create %s", dest_dir)
            else:
                logger.info("creating %s", dest_dir)
                dest_dir.mkdir(parents=True)

        for path in source_dir.iterdir():
            if self.relative_links:
                target = relative_to(dest_dir, path)
            else:
                target = path

            link = dest_dir.joinpath(path.name)
            if transformer:
                link = transformer(link)

            if (link.exists() and target.exists() and link.samefile(target)) or (
                link.is_symlink() and link.resolve() == target.resolve()
            ):
                # same file!
                if self.dry_run:
                    logger.info("would skip %s", link)
                else:
                    logger.info("skipping %s", path)
                continue

            if link.exists() or link.is_symlink():
                # conflict!
                if self.on_conflict == "overwrite":
                    self._remove_path(link)
                elif self.on_conflict == "rename":
                    self._rename_path(link)
                elif self.on_conflict == "skip":
                    if self.dry_run:
                        logger.info("would skip %s", link)
                    else:
                        logger.info("skipping %s", link)
                    continue
                else:
                    raise ValueError("what's this?", self.on_conflict)

            self._link_paths(target=target, link=link)

    def _remove_path(self, path: Path) -> None:
        """Remove the file or directory at the given path."""
        if self.dry_run:
            logger.info("would remove %s", path)
            return

        logger.info("removing %s", path)
        if path.is_dir() and not path.is_symlink() and not is_junction(path):
            shutil.rmtree(path)
        else:
            path.unlink()

    def _rename_path(self, path: Path) -> None:
        replacement = self._tr_backup(path)
        if self.dry_run:
            logger.info("would preserve %s as %s", path, replacement)
            return

        logger.info("preserving %s as %s", path, replacement)
        path.replace(replacement)
        return

    def _link_paths(
        self,
        target: Path,
        link: Path,
    ) -> None:
        """
        Create a link to path `target` at path `link`.

        `target` should exist, and `link` should not. If `symbolic` is True, a
        symbolic link is created. If `symbolic` is False, a hard link (or a
        Junction) is created. If `symbolic` is None, then hard links (or Junctions)
        are created on Windows (`os.name == "nt"`), and symbolic links are created
        otherwise.
        """

        assert isinstance(target, (Path, str))
        assert isinstance(link, (Path, str))

        target, link = Path(target), Path(link)

        logger.info("%s -> %s", link, target)
        if self.dry_run:
            return

        if self.symbolic_links:
            os.symlink(target, link)
        elif target.is_dir():
            CreateJunction(str(target), str(link))
        else:
            os.link(target, link)

    def _tr_dotfile(self, path):
        """Transform `Path('filename.txt')` to `Path('.filename.txt')`."""
        return path.with_name("." + path.name)

    def _tr_backup(self, path):
        """Transform `Path('filename.txt')` to `Path('filename.txt.bak')`."""
        new_suffix = "".join(path.suffixes + [".bak"])
        return path.with_suffix(new_suffix)


def relative_to(path: Path, target: Path) -> Path:
    """Return the relative path from `path` to `target`."""
    ancestor = Path(os.path.commonpath([path, target]))
    backtrack = "../" * len(path.relative_to(ancestor).parents)
    return Path(backtrack + str(target.relative_to(ancestor)))


def get_installer(argv: list[str] | None = None) -> Installer:
    """Build a Settings object based on CLI arguments."""

    parser = argparse.ArgumentParser(description=DESCRIPTION)
    parser.add_argument(
        "-R",
        "--relative-links",
        action="store_true",
        help="make relative symbolic links (implies `--symbolic-links`)",
    )
    parser.add_argument(
        "-D",
        "--dry-run",
        action="store_true",
        help="make no changes; describe what actions would be taken",
    )
    parser.add_argument(
        "-S",
        "--symbolic-links",
        action="store_true",
        help="Create symbolic links",
    )

    conflict_group = parser.add_mutually_exclusive_group()
    conflict_group.add_argument(
        "-r",
        "--rename-conflicts",
        action="store_const",
        dest="conflict",
        const="rename",
        default="skip",
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
        help="overwrite conflicting files",
    )

    args = parser.parse_args(argv)

    return Installer(
        dry_run=args.dry_run,
        relative_links=args.relative_links,
        symbolic_links=args.relative_links or args.symbolic_links,
        on_conflict=args.conflict,
    )


if __name__ == "__main__":
    installer = get_installer()
    installer.install()
