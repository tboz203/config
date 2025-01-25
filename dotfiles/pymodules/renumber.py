from __future__ import annotations

import logging
import re
from argparse import ArgumentParser, Namespace
from os import PathLike
from pathlib import Path
from shutil import move
from typing import TYPE_CHECKING, Any

if TYPE_CHECKING:
    from collections.abc import Sequence
    from os import PathLike

NAME_PATTERN = re.compile(r"^(?P<stem>.*) \((?P<number>\d+)\)$")
NAME_TEMPLATE = "{path.stem} ({number}){path.suffix}"

logger = logging.getLogger("mrn")
logging.basicConfig(format="%(name)s: %(message)s", level=logging.INFO)


def get_numbered_name(path: Path | PathLike[str]) -> Path:
    path = Path(path)
    if not path.parent.exists():
        raise FileNotFoundError(path.parent)

    if match := NAME_PATTERN.match(path.stem):
        stem = match.group("stem")
    else:
        stem = path.stem

    base = path.with_stem(stem)
    if not base.exists():
        return base

    for i in range(1, 100):
        dest = path.parent / NAME_TEMPLATE.format(path=base, number=i)
        if not dest.exists():
            return dest

    raise FileExistsError(1, "Cowardly refusing to make more", base)


def move_rename(
    source: Path | PathLike[str],
    dest: Path | PathLike[str],
    *,
    dest_as_directory: bool | None = None,
    dryrun: bool = False,
) -> None:
    """
    Move and perhaps rename a single file.

    :param source: The path of the file (or directory) to be moved. Must exist.
    :param dest: The path where `source` will be moved to. May exist.
    :param dest_as_directory: Whether `dest` must be treated as a directory, as a file, or either.
    """

    if not source:
        raise ValueError("Invalid source", source)
    if not dest:
        raise ValueError("Invalid dest", dest)

    source = Path(source)
    dest = Path(dest)

    # dest_as_directory -> | True         | False       | None
    # dest on disk -v      |              |             |
    # -------------------- | ------------ | ----------- | -----------
    # file exists          | err          | get_numbered_name | get_numbered_name
    # directory exists     | joinpath     | get_numbered_name | joinpath
    # does not exist       | mkdir?       | move        | move

    if dest_as_directory:
        if dest.is_file():
            raise NotADirectoryError(dest)
        if not dest.exists():
            logger.info("Creating dest directory: %s", dest)
            if not dryrun:
                dest.mkdir()

    if dest.is_dir() and dest_as_directory is not False:
        dest /= source.name

    dest = get_numbered_name(dest)
    logger.info("%s -> %s", source, dest)
    if not dryrun:
        move(source, dest)


def parse_args(args: Sequence[str] | None = None) -> Namespace:
    """
    Parse arguments for this module as a script.

    Our argument schema was specially chosen to approximate GNU `mv`s API.
    """
    parser = ArgumentParser(description=__doc__)

    # an observant developer may note that we have a multi followed by an
    # optional, meaning that `directory` will never be populated by argparse.
    # after argparse does its work, we examine our arguments as a whole, and
    # take `directory` from `source` if necessary.
    parser.add_argument(
        "source",
        metavar="SOURCE",
        nargs="+",
        help="The file(s) to be moved, and perhaps renamed.",
    )
    parser.add_argument(
        "dest",
        metavar="DEST",
        nargs="?",
        help="The destination to move files to.",
    )
    parser.add_argument(
        "-n",
        "--dry-run",
        action="store_true",
        help="Look, but don't touch",
    )

    target_group = parser.add_mutually_exclusive_group()
    target_group.add_argument(
        "-t",
        "--target-directory",
        help="The directory to move files to.",
    )
    target_group.add_argument(
        "-T",
        "--no-target-directory",
        action="store_true",
        help="Treat DEST as a normal file",
    )

    parsed_args: Any = parser.parse_args(args)
    del args

    if parsed_args.target_directory is not None:
        # we were given a `--target-directory` option, and should use that as
        # our destination
        parsed_args.dest = parsed_args.target_directory
        parsed_args.dest_as_directory = True
    else:
        # we were not given a `--target-directory` option, and should use the
        # last item from `source` as our destination
        parsed_args.dest = parsed_args.source.pop()

        if parsed_args.no_target_directory:
            parsed_args.dest_as_directory = False
        else:
            parsed_args.dest_as_directory = None

        # if `source` is now empty, we weren't given enough arguments
        if not parsed_args.source:
            parser.error("Missing DEST argument")

    del parsed_args.target_directory

    return parsed_args


def main():
    """As a script, move and rename files."""

    args = parse_args()

    for item in args.source:
        try:
            move_rename(
                item,
                args.dest,
                dest_as_directory=args.dest_as_directory,
                dryrun=args.dry_run,
            )
        except KeyboardInterrupt:
            exit(1)
        except Exception as exc:
            exit(str(exc))

    exit(0)


if __name__ == "__main__":
    main()
