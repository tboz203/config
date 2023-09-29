#!/usr/bin/env python
'''sort logs by timestamp (as long as its the first field)'''

import argparse
import fileinput
import re

from textwrap import dedent, fill
from typing import Iterator


def _strclean(text: str) -> str:
    """Clean up string whitespace."""
    return fill(dedent(text).strip())


def main() -> None:
    parser = argparse.ArgumentParser(
        description=_strclean(
            """
            Sort log entries.

            Assumes that log entries start with (and are delimited by lines that
            start with) an ISO-8601 timestamp, with optional fractional seconds.
            """
        )
    )
    parser.add_argument("files", nargs="*", help='files to be read from. "-" means stdin; defaults to "-"')
    args = parser.parse_args()
    lines = fileinput.input(args.files)
    lines = sort_logs(lines)
    print("".join(lines))


def sort_logs(lines: Iterator[str]) -> list[str]:
    pattern = re.compile(r'^\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d(\.\d{1,9})?')

    # collect any multiline blobs

    current_blob = None
    blobs = []

    for line in lines:
        if pattern.search(line):
            # we've got the start of a new blob
            # put any currently held blob into the list
            if current_blob:
                blobs.append(current_blob)
            current_blob = line
        else:
            current_blob += line
    if current_blob:
        blobs.append(current_blob)

    # then sort our blobs
    blobs = sorted(blobs, key=(lambda b: match.group(0) if (match := pattern.search(b)) else None))

    return blobs


if __name__ == '__main__':
    main()
