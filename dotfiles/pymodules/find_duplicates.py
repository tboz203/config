#!/usr/bin/env python
"""Find (and optionally remove) duplicate files."""

from __future__ import annotations

import argparse
import logging
import zlib
from contextlib import contextmanager
from pathlib import Path
from pprint import pformat
from shutil import get_terminal_size

logging.basicConfig(level=logging.INFO, format="[%(levelname)-8s %(name)s]: %(message)s")

# something like "rmdups"
my_name = Path(__file__).stem
logger = logging.getLogger(my_name)


class Spinner:
    spinner_chars = ['/', '-', '\\', '|']

    def __init__(self, count: int, increment: int = 1, width: int = 40):
        self.count = count
        self.width = width
        self.increment = increment
        self.index = 0

    def spin(self, increment: Optional[int] = None):
        self.index += (increment or self.increment)
        spin = self.spinner_chars[self.index % len(self.spinner_chars)]
        progress = '#' * ( self.width * self.index // max(self.count - 1, 1))
        print(f'\x1b[0G\x1b[0K{spin} [{progress:{self.width}s}]', end='')

    def __enter__(self):
        self.index = 0
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        print()


def hash_file(name: str | Path) -> str:
    """Compute a hash of a file's contents"""
    return hex(zlib.crc32(Path(name).read_bytes()))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("paths", metavar="FILES", nargs="+", type=Path, help="Files to be checked for duplicates")
    parser.add_argument("--rm", action="store_true", help="Delete any file which is a duplicate of a previous file")
    parser.add_argument("-r", "--recurse", action="store_true", help="Search paths recursively")
    args = parser.parse_args()

    file_list: list[Path] = []

    for path in args.paths:
        if path.is_file():
            file_list.append(path)
        elif path.is_dir():
            if args.recurse:
                file_list += [p for p in path.rglob('*') if p.is_file()]
            else:
                logger.warning("Skipping directory (not in recursive mode): %s", path)
        else:
            logger.warning("Skipping non-regular file: %s", path)

    logger.info("Hashing %s files", len(file_list))

    # collect hashes
    file_hash_map: dict[str, list[Path]] = {}
    if logger.isEnabledFor(logging.INFO):
        with Spinner(len(file_list)) as spinner:
            for path in file_list:
                spinner.spin()
                file_hash_map.setdefault(hash_file(path), []).append(path)
    else:
        for path in file_list:
            file_hash_map.setdefault(hash_file(path), []).append(path)

    unique: dict[str, Path] = {}
    duplicates: dict[str, list[Path]] = {}
    for file_hash, file_list in file_hash_map.items():
        if len(file_list) == 1:
            unique[file_hash] = file_list[0]
        else:
            duplicates[file_hash] = file_list

    logger._log(
        logging.INFO,
        f"Found {len(unique)} unique and {sum(map(len, duplicates.values()))} duplicated files",
        ()
    )

    if args.rm:
        for group in duplicates.values():
            first = group[0]
            logger.info("Keeping:  %s", first)
            for dup in group[1:]:
                logger.info("Removing: %s", dup)
                dup.unlink()
    elif logger.isEnabledFor(logging.INFO):
        for group in duplicates.values():
            first = group[0]
            logger.info("Would keep:   %s", first)
            for dup in group[1:]:
                logger.info("Would remove: %s", dup)


if __name__ == "__main__":
    main()
