"""
Manage file names with embedded revision numbers.
"""

from __future__ import annotations

import logging
import re
from argparse import ArgumentParser
from pathlib import Path
from shutil import move
from typing import TYPE_CHECKING, Any

if TYPE_CHECKING:
    from argparse import Namespace
    from collections.abc import Sequence

NAME_PATTERN = re.compile(r"^(?P<stem>.*) \((?P<number>\d+)\)$")
NAME_TEMPLATE = "{stem} ({number})"

logger = logging.getLogger("renumber")
logging.basicConfig(format="%(name)s: %(message)s", level=logging.INFO)


def move_and_renumber(
    sources: Sequence[Path],
    destination: Path,
    *,
    dest_as_directory: bool | None = None,
    dryrun: bool = False,
    copy: bool = False,
):
    # I want to be able to move a bunch of files named like 'example (2).png'
    # to a directory that ALSO has a bunch of files named like 'example
    # (2).png' and I want them all to get along. It would also be cool if I
    # could have a proper `dry-run` mode that tells me where everything would
    # land without making any changes.

    # it should be able to take a number of input files, in whatever order, all
    # in the same directory, and rename them all to the same form, potentially
    # even swapping names between existing input files

    # * capture the initial state
    #   * resolve the parent of each source
    #   * get full listing of target directory (destination or its parent)
    # * determine desired state
    #   * if not copying, find any source items already in the target directory
    #     and remove them from our listing
    #   * for each source item, determine the first available destination name
    #     in the target directory listing
    # * if dry-run, present this state-mapping "plan"
    # * if not dry-run, execute the plan
    #   * if copying, perform each copy in argument order
    #   * if not copying, any source items already in the target directory
    #     should be -- what if one source item contains another?

    # cases:
    # an earlier source item is a directory that contains a latter source item
    # an earlier source item is contained by a latter source item directory
    # any source item is a directory that contains the target directory
    # ...

    # ...
    # what about if a source item is listed multiple times?
    # what considerations need to be made for hard links or symbolic links?

    pass


# def get_numbered_name(path: Path | str) -> Path:
#     path = Path(path)
#     if not path.parent.exists():
#         raise FileNotFoundError(path.parent)
#
#     if match := NAME_PATTERN.match(path.stem):
#         stem = match.group("stem")
#     else:
#         stem = path.stem
#
#     base = path.with_stem(stem)
#     if not base.exists():
#         return base
#
#     for i in range(1, 100):
#         dest = path.parent / NAME_TEMPLATE.format(path=base, number=i)
#         if not dest.exists():
#             return dest
#
#     raise FileExistsError(1, "Cowardly refusing to make more", base)
#
#
# def move_rename(
#     source: Path | str,
#     dest: Path | str,
#     *,
#     dest_as_directory: bool | None = None,
#     dryrun: bool = False,
# ) -> None:
#     """
#     Move and perhaps rename a single file.
#
#     :param source: The path of the file (or directory) to be moved. Must exist.
#     :param dest: The path where `source` will be moved to. May exist.
#     :param dest_as_directory: Whether `dest` must be treated as a directory, as a file, or either.
#     """
#
#     if not source:
#         raise ValueError("Invalid source", source)
#     if not dest:
#         raise ValueError("Invalid dest", dest)
#
#     source = Path(source)
#     dest = Path(dest)
#
#     # dest_as_directory -> | True         | False       | None
#     # dest on disk -v      |              |             |
#     # -------------------- | ------------ | ----------- | -----------
#     # file exists          | err          | get_numbered_name | get_numbered_name
#     # directory exists     | joinpath     | get_numbered_name | joinpath
#     # does not exist       | mkdir?       | move        | move
#
#     if dest_as_directory:
#         if dest.is_file():
#             raise NotADirectoryError(dest)
#         if not dest.exists():
#             logger.info("Creating dest directory: %s", dest)
#             if not dryrun:
#                 dest.mkdir()
#
#     if dest.is_dir() and dest_as_directory is not False:
#         dest /= source.name
#
#     dest = get_numbered_name(dest)
#     logger.info("%s -> %s", source, dest)
#     if not dryrun:
#         move(source, dest)


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
        type=Path,
        nargs="+",
        help="The file(s) to be moved, and perhaps renamed.",
    )
    parser.add_argument(
        "dest",
        metavar="DEST",
        type=Path,
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
        type=Path,
        metavar="DEST",
        help="The directory to move files to.",
    )
    target_group.add_argument(
        "-T",
        "--no-target-directory",
        dest="dest_as_directory",
        action="store_false",
        default=None,
        help="Treat DEST as a normal file",
    )

    parsed_args: Any = parser.parse_args(args)
    del args

    logger.info("Base Args: %s", parsed_args)

    if parsed_args.target_directory is not None:
        # we were given a `--target-directory` option, and should use that as
        # our destination
        parsed_args.dest = parsed_args.target_directory
        parsed_args.dest_as_directory = True
    else:
        # we were not given a `--target-directory` option, and should use the
        # last item from `source` as our destination
        parsed_args.dest = parsed_args.source.pop()

        # if `source` is now empty, we weren't given enough arguments
        if not parsed_args.source:
            parser.error("Missing DEST argument")

    del parsed_args.target_directory

    logger.info("Parsed Args: %s", parsed_args)
    return parsed_args


def main() -> Any:
    """As a script, move and rename files."""

    args = parse_args()

    try:
        move_and_renumber(
            args.source,
            args.dest,
            dest_as_directory=args.dest_as_directory,
            dryrun=args.dry_run,
        )
    except KeyboardInterrupt:
        return 1
    except Exception as exc:
        return exc


if __name__ == "__main__":
    exit(main())
