#!/usr/local/bin/python3
"""Find duplicate files."""

from __future__ import annotations

import argparse
import logging
from collections import defaultdict
from hashlib import sha256
from pathlib import Path
from pprint import pformat
from shutil import get_terminal_size

logger = logging.getLogger("rmdups")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("paths", metavar="FILES", nargs="+", type=Path, help="Files to be checked for duplicates")
    parser.add_argument("--rm", action="store_true", help="Delete any file which is a duplicate of a previous file")
    args = parser.parse_args()

    file_hashes: dict[str, list[Path]] = defaultdict(list)

    path: Path
    for path in args.paths:
        if path.is_dir():
            logger.warning("Skipping directory: %s", path)
            continue
        filehash = hash_file(path)
        if filehash in file_hashes and args.rm:
            first_matched = file_hashes[filehash][0]
            logger.info("Found duplicated file: %s <- %s", first_matched, path)
            logger.info("Removing file: %s", path)
            # path.unlink()
        file_hashes[filehash].append(path)

    if logger.isEnabledFor(logging.INFO):
        formatted = pformat(file_hashes, width=get_terminal_size().columns)
        logger.info("File Hashes:\n%s", formatted)


def hash_file(name: str | Path) -> str:
    """Compute the hash of a file's contents"""
    bin_contents = Path(name).read_bytes()
    return sha256(bin_contents).hexdigest()


if __name__ == "__main__":
    main()
