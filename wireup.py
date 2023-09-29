#!/usr/bin/env python3
"""
install dotfiles as symlinks
"""

import argparse
import logging
import os
import shutil
from pathlib import Path

ROOT = Path(__file__).absolute().parent
DESCRIPTION = __doc__
logging.basicConfig(level=logging.INFO, format='%(levelname)s: %(message)s')
logger = logging.getLogger(__name__)


def destroy_path(path):
    if path.is_dir() and not path.is_symlink():
        shutil.rmtree(path)
    else:
        path.unlink()


def preserve_path(path):
    new_suffix = ''.join(path.suffixes + ['.bak'])
    path.replace(path.with_suffix(new_suffix))


def relative_to(path, target):
    """
    return the relative path from `path` to `target`, backtracking to parent
    directories if necessary
    """
    ancestor = Path(os.path.commonpath([path, target]))
    backtrack = '../' * len(path.relative_to(ancestor).parents)
    return Path(backtrack + str(target.relative_to(ancestor)))


def link_files(source_dir, target_dir, relative, preserve, dryrun, transformer=None):
    """
    link files from one directory to another
    """
    for path in source_dir.iterdir():
        link = target_dir.joinpath(path.name)
        if transformer:
            link = transformer(link)
        if link.exists() or link.is_symlink():
            if preserve:
                logger.info('preserving %s', link)
                if not dryrun:
                    preserve_path(link)
            else:
                logger.info('destroying %s', link)
                if not dryrun:
                    destroy_path(link)
        if relative:
            path = relative_to(target_dir, path)
        logger.info('%s -> %s', link, path)
        if not dryrun:
            link.symlink_to(path)


def wireup(config_root, homedir, configdir, sshdir, relative=True, preserve=False, dryrun=True):
    """
    install files

    :param config_root: root of the `config` project
    :type  config_root: Path-like
    :param homedir: the home directory to install to
    :type  homedir: Path-like
    :param configdir: the config directory to install to
    :type  configdir: Path-like
    :param sshdir: the ssh directory to install to
    :type  sshdir: Path-like
    :param relative: create relative symlinks, defaults to True
    :type  relative: bool
    :param preserve: rename existing files to `*.bak`, defaults to False
    :type  preserve: bool
    :param dryrun: look but don't touch, defaults to False
    :type  dryrun: bool

    :return: None
    """

    config_root = Path(config_root).absolute()
    homedir = Path(homedir).absolute()
    configdir = Path(configdir).absolute()
    sshdir = Path(sshdir).absolute()
    settings = {"relative": relative, "preserve": preserve, "dryrun": dryrun}

    # first dotfiles
    dotfile_transformer = lambda p: p.with_name('.' + p.name)
    link_files(config_root.joinpath('dotfiles'), homedir, **settings, transformer=dotfile_transformer)

    # then configfiles
    link_files(config_root.joinpath('configfiles'), configdir, **settings)

    # then sshfiles
    link_files(config_root.joinpath('sshfiles'), sshdir, **settings)



def main():
    parser = argparse.ArgumentParser(description=DESCRIPTION)
    parser.add_argument('-r', '--relative', action='store_true', help='make relative symlinks')
    parser.add_argument('-p', '--preserve', action='store_true', help='rename existing files to `*.bak`')
    parser.add_argument('-d', '--dryrun', '--dry-run', action='store_true', help="look but don't touch")
    args = parser.parse_args()

    wireup(
        config_root=ROOT,
        homedir=Path.home(),
        configdir=Path.home().joinpath('.config'),
        sshdir=Path.home().joinpath('.ssh'),
        relative=args.relative,
        preserve=args.preserve,
        dryrun=args.dryrun,
    )


if __name__ == '__main__':
    main()
