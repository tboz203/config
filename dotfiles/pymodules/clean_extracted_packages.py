#!/usr/local/bin/python3
"""Clean extracted packages.

This script examines tar & zip packages, and removes files and directories that
have been extracted from them.
"""

import argparse
import logging
import tarfile
import zipfile
from itertools import islice
from pathlib import Path
from shutil import rmtree
from typing import Iterator, Optional

Pathlike = Path | str

PACKAGE_SUFFIXES = [
    ".tar",
    ".tar.gz",
    ".tar.xz",
    ".tar.bz2",
    ".tgz",
    ".txz",
    ".tbz2",
    ".zip",
]

# a new log level between info & warning
NOTICE = 25
logging.addLevelName(NOTICE, "NOTICE")
logging.basicConfig(format="[%(levelname)-8s] %(message)s")
logger = logging.getLogger("clean_extracted_packages")


def list_packages(directory: Pathlike) -> Iterator[Path]:
    """find all package files in `directory`"""
    logger.debug("Finding packages in directory: %s", directory)
    directory = Path(directory)
    for suffix in PACKAGE_SUFFIXES:
        yield from directory.glob(f"*{suffix}")


def determine_package_root(package_file: Pathlike, strict: bool = False) -> Optional[str]:
    """Given a package filename, examine it and pick its contained root file.

    If the given package has more than one root member, return None. If `strict`,
    this function reads entire tarfiles, which may take some time. If not
    `strict` (the default), only read a subset of tarfile contents.
    """

    if tarfile.is_tarfile(package_file):
        logger.info("reading tarfile: %s", package_file)
        with tarfile.open(package_file) as tarball:
            if strict:
                # collect all names
                name_sample = tarball.getnames()
            else:
                # collect *some* names
                name_sample = [item.name for item in islice(tarball, 20)]
    elif zipfile.is_zipfile(package_file):
        logger.info("reading zipfile: %s", package_file)
        with zipfile.ZipFile(package_file) as zipball:
            # collect all names
            name_sample = zipball.namelist()
    else:
        logger.warning("unrecognized package type: %s", package_file)
        return None

    name_sample = [name.removeprefix("./").strip("/") for name in name_sample]
    all_roots = {name.split("/")[0] for name in name_sample}
    if len(all_roots) != 1:
        logger.info("Could not determine unique package root: %s", all_roots)
        return None
    root = all_roots.pop()
    logger.debug("determined package root for %s: %s", package_file, root)
    return root


def guess_package_root(package_file: Pathlike) -> Optional[str]:
    """Given a package name, guess what it may be extracted to based on name alone.

    This method is much faster than `determine_package_root`, but also less reliable.
    """
    if isinstance(package_file, Path):
        package_file = package_file.as_posix()
    for suffix in PACKAGE_SUFFIXES:
        if package_file.endswith(suffix):
            guess = package_file.removesuffix(suffix)
            logger.debug("guessed package root for %s: %s", package_file, guess)
            return guess

    # this shouldn't happen; looking at these package suffixes is how we find
    # packages in the first place...
    logger.log(NOTICE, "no guesses for package??: %s", package_file)


def find_package_extraction(package_file: Pathlike, directory: Pathlike, strict: bool = False) -> Optional[Path]:
    """Determine where a package has been extracted to.

    May guess based on package name; may read package to determine contents.
    If not `strict` (default=False), only reads subset of tarball contents.
    """
    package_file = Path(package_file)
    directory = Path(directory)
    if package_file.is_dir():
        raise ValueError("cannot find extraction: package_file is a directory", package_file)

    maybe_root_guess = guess_package_root(package_file)
    if maybe_root_guess:
        maybe_extracted_path = directory.joinpath(maybe_root_guess)
        if maybe_extracted_path.exists():
            logger.info("guessing %s -> %s", package_file, maybe_extracted_path)
            return maybe_extracted_path
        else:
            logger.debug("guessed root does not exist: %s, %s", package_file, maybe_extracted_path)

    maybe_root = determine_package_root(package_file, strict)
    if not maybe_root:
        logger.warning("package has no root: %s", package_file)
        return None
    maybe_extracted_path = directory.joinpath(maybe_root)
    if maybe_extracted_path.exists():
        logger.info("Found extracted package: %s", maybe_extracted_path)
        return maybe_extracted_path

    return None


def clean_extracted_packages(directory: Pathlike, dryrun: bool = False, strict: bool = False) -> list[str]:
    """Clean extracted packages in a directory.

    returns any exceptions encountered as strings."""
    problems: list[str] = []
    for package in list_packages(directory):
        extraction = find_package_extraction(package, directory, strict)
        if extraction:
            if extraction.as_posix() in [".", "..", "/"]:
                raise RuntimeError("refusing to delete: %s", extraction)
            if dryrun:
                logger.log(NOTICE, "would remove extracted package: %s", extraction)
            else:
                logger.log(NOTICE, "removing extracted package: %s", extraction)
                try:
                    if extraction.is_dir():
                        rmtree(extraction)
                    else:
                        extraction.unlink()
                except OSError as exc:
                    logger.error("Failed to remove extracted package: %s", exc)
                    problems.append(f"{extraction}: {exc}")

    return problems


def parse_args(args: Optional[list[str]] = None) -> argparse.Namespace:
    """Parse arguments for this script."""
    # use module docstring as description
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument(
        "-n",
        "--dryrun",
        "--dry-run",
        action="store_true",
        help="show what files or directories would be removed, but remove nothing",
    )
    parser.add_argument(
        "-s",
        "--strict",
        action="store_true",
        default=False,
        help="don't be lazy; read entire tarball to decide root directory",
    )
    parser.add_argument(
        "-l",
        "--lazy",
        dest="strict",
        action="store_false",
        help="don't be strict; guess tarball root directory from first ~20 items",
    )
    parser.add_argument(
        "-v",
        "--verbose",
        action="count",
        default=0,
        help="increase script verbosity; may be repeated",
    )
    parser.add_argument(
        "-q",
        "--quiet",
        action="count",
        default=0,
        help="decrease script verbosity; may be repeated",
    )
    parser.add_argument(
        "directories",
        nargs="*",
        default=["."],
        help="the directories to clean. defaults to current directory",
    )
    return parser.parse_args(args=args)


def init_logging(args: argparse.Namespace) -> None:
    """Set logging level based on args."""
    verbosity = args.verbose - args.quiet

    if verbosity >= 2:
        logging.root.setLevel(logging.DEBUG)
    elif verbosity >= 1:
        logging.root.setLevel(logging.INFO)
    elif verbosity >= 0:
        logging.root.setLevel(NOTICE)
    elif verbosity >= -1:
        logging.root.setLevel(logging.WARNING)
    elif verbosity >= -2:
        logging.root.setLevel(logging.ERROR)
    else:
        logging.root.setLevel(logging.CRITICAL)


def main():
    """Clean extracted packages."""
    args = parse_args()
    init_logging(args)

    all_problems: dict[str, list[str]] = {}
    for directory in args.directories:
        any_problems = clean_extracted_packages(directory, args.dryrun, args.strict)
        if any_problems:
            all_problems[directory] = any_problems

    if all_problems:
        logger.log(NOTICE, "Cleaning complete; listing problems encountered...")
        for directory, problems in all_problems.items():
            for problem in problems:
                logger.log(NOTICE, "problem in %s: %s", directory, problem)

    logger.log(NOTICE, "All done! remember to also clean git repositories!")
    exit(bool(all_problems))


if __name__ == "__main__":
    main()
