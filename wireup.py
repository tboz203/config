#!/usr/bin/env python3
"""
Install dotfiles as symlinks
"""

import argparse
import logging
import os
import shutil
from pathlib import Path

ROOT = Path(__file__).absolute().parent
logging.basicConfig(level=logging.INFO, format="%(levelname)s: %(message)s")
logger = logging.getLogger(__name__)


class Installer:
    """
    A class to manage installing my config.
    """

    def __init__(self, config_root, homedir, configdir, sshdir, relative=True, preserve=False, dryrun=True):
        """
        Create a new Installer.

        `config_root` should be the root of a "config" directory (such as this git repository)
        `homedir` should be your home directory
        `configdir` should be your config directory (e.g. `~/.config`)
        `sshdir` should be your ssh directory (e.g `~/.ssh`)

        `relative` determines whether or not created symbolic links are relative or absolute
        `preserve` determines whether existing files are removed or preserved (renamed)
        `dryrun` determines whether actions are performed, or just displayed
        """
        self.config_root = Path(config_root).absolute()
        self.homedir = Path(homedir).absolute()
        self.configdir = Path(configdir).absolute()
        self.sshdir = Path(sshdir).absolute()

        self.relative = relative
        self.preserve = preserve
        self.dryrun = dryrun

    def install(self):
        """Install links from each managed directory."""
        self.install_links(self.config_root.joinpath("dotfiles"), self.homedir, transform=self.tr_dotfile)
        self.install_links(self.config_root.joinpath("configfiles"), self.configdir)
        self.install_links(self.config_root.joinpath("sshfiles"), self.sshdir)

    def install_links(self, source_dir, target_dir, transform=None):
        """Install links from one directory to another."""

        for path in source_dir.iterdir():
            link = target_dir.joinpath(path.name)

            if transform:
                link = transform(link)

            if link.exists() or link.is_symlink():
                self.remove_path(link)

            self.link_path(path, link)

    def remove_path(self, path):
        if self.preserve:
            replacement = self.tr_backup(path)
            if self.dryrun:
                logger.info("would preserve %s as %s", path, replacement)
                return

            logger.info("preserving %s as %s", path, replacement)
            path.replace(replacement)
            return

        if self.dryrun:
            logger.info("would remove %s", path)
            return

        logger.info("removing %s", path)
        if path.is_dir() and not path.is_symlink():
            shutil.rmtree(path)
        else:
            path.unlink()

    def link_path(self, source, target):
        if self.relative:
            source = relative_to(target.parent, source)

        if self.dryrun:
            logger.info("would link %s to %s", target, source)
            return

        logger.info("linking %s to %s", target, source)
        target.parent.mkdir(parents=True, exist_ok=True)
        target.symlink_to(source)

    def tr_dotfile(self, path):
        """Transform `Path('filename.txt')` to `Path('.filename.txt')`."""
        return path.with_name("." + path.name)

    def tr_backup(self, path):
        """Transform `Path('filename.txt')` to `Path('filename.txt.bak')`."""
        new_suffix = "".join(path.suffixes + [".bak"])
        return path.with_suffix(new_suffix)


def relative_to(path, target):
    """
    return the relative path from `path` to `target`, backtracking to parent
    directories if necessary
    """

    ancestor = Path(os.path.commonpath([path, target]))
    backtrack = "../" * len(path.relative_to(ancestor).parents)
    return Path(backtrack + str(target.relative_to(ancestor)))


def main():
    parser = argparse.ArgumentParser(description=(__doc__ or "").strip())
    parser.add_argument("-r", "--relative", action="store_true", help="make relative symlinks")
    parser.add_argument("-p", "--preserve", action="store_true", help="rename existing files to `*.bak`")
    parser.add_argument("-d", "--dryrun", "--dry-run", action="store_true", help="look but don't touch")
    args = parser.parse_args()

    installer = Installer(
        config_root=ROOT,
        homedir=Path.home(),
        configdir=Path.home().joinpath(".config"),
        sshdir=Path.home().joinpath(".ssh"),
        relative=args.relative,
        preserve=args.preserve,
        dryrun=args.dryrun,
    )

    installer.install()


if __name__ == "__main__":
    main()
