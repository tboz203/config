#!/usr/local/bin/python3
"""
Filter log entries.

Assumes that log entries start with (and are delimited by lines that
start with) an ISO-8601 timestamp, with optional fractional seconds.
"""

import argparse
import fileinput
import re
import sys
from collections.abc import Callable, Iterable, Iterator, Sequence
from pathlib import Path
from typing import Optional

# pattern matching ISO-8601 timestamp at start of line
TIMESTAMP_PATTERN = r"^\d{4}-\d\d-\d\d[T ]\d\d:\d\d:\d\d(?:\.\d{1,9})?"


def parse_args(arg_strings: Optional[Sequence[str]] = None) -> argparse.Namespace:
    """
    Parse command line arguments into an argparse Namespace.
    Uses `args` argument if passed, otherwise uses sys.argv.
    """
    script_path = Path(sys.argv[0])
    called_sort_logs = script_path.stem == "sort-logs"

    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument(
        "--join",
        action=argparse.BooleanOptionalAction,
        default=True,
        help="Join physical lines into logical lines that start with a specific header.",
    )
    parser.add_argument(
        "-p",
        "--pattern",
        default=TIMESTAMP_PATTERN,
        help="A regular expression pattern for matching the first physical line in a logical line.",
    )
    parser.add_argument(
        "-s",
        "--sort",
        default=called_sort_logs,
        action=argparse.BooleanOptionalAction,
        help="Sort log lines using the log pattern.",
    )
    parser.add_argument(
        "-u",
        "--unique",
        action=argparse.BooleanOptionalAction,
        help="Squash duplicate log lines (does not imply --sort).",
    )
    parser.add_argument(
        "-f",
        "--filter",
        action="append",
        help="only include lines matching a given regular expression. May be repeated",
    )
    parser.add_argument(
        "-e",
        "--exclude",
        action="append",
        help="exclude lines matching a given regular expression. May be repeated",
    )

    output_group = parser.add_mutually_exclusive_group()
    output_group.add_argument("-o", "--output", help="write output to file")
    output_group.add_argument("-a", "--append", help="append output to file")

    parser.add_argument("files", nargs="*", default="-", help='Files to be read from. "-" means stdin.')
    return parser.parse_args(arg_strings)


def main(arg_strings: Optional[Sequence[str]] = None) -> None:
    """Parse arguments, read input, filter log lines, and display."""
    args = parse_args(arg_strings)
    lines: Iterable[str] = fileinput.input(args.files)
    lines = logfilter(
        lines,
        join=args.join,
        join_pattern=args.pattern,
        sort=args.sort,
        sort_pattern=args.pattern,
        unique=args.unique,
        filters=args.filter,
        exclusions=args.exclude,
    )
    output_lines(lines, args.output or args.append, bool(args.append))


def logfilter(
    lines: Iterable[str],
    *,
    join: bool = True,
    join_pattern: str = TIMESTAMP_PATTERN,
    sort: bool = True,
    sort_pattern: str = TIMESTAMP_PATTERN,
    unique: bool = False,
    filters: Optional[Sequence[str]] = None,
    exclusions: Optional[Sequence[str]] = None,
) -> Iterable[str]:
    """Filter log entries."""
    if join:
        lines = join_lines(lines, join_pattern)
    if unique:
        lines = unique_lines(lines)
    if filters:
        for filter_pat in filters:
            lines = filter_lines(filter_pat, lines)
    if exclusions:
        for exclude_pat in exclusions:
            lines = exclude_lines(exclude_pat, lines)
    if sort:
        lines = sorted(lines, key=make_key_function(sort_pattern))
    return lines


def make_key_function(pattern: str) -> Callable[[str], tuple[str, str]]:
    """Generate a `sort` key function for log entry headers."""
    regex = re.compile(pattern)
    # if the given regex has any capture groups, sort based on the first one
    groupindex = 1 if regex.groups else 0

    def key_function(blob: str) -> tuple[str, str]:
        if match := regex.search(blob):
            return (match.group(groupindex), blob)
        return ("", blob)

    return key_function


def join_lines(lines: Iterable[str], pattern: str) -> Iterator[str]:
    """
    Join physical log lines into logical log lines.

    Takes an iterable of strings separated by newlines, and returns an iterable
    of strings beginning with a log header pattern.
    """
    # if we never match any lines, something is wrong
    any_matches = False

    regex = re.compile(pattern)

    current_blob = ""
    for line in lines:
        if regex.search(line):
            any_matches = True
            # we've got the start of a new blob
            # put any currently held blob into the list
            if current_blob:
                yield current_blob.rstrip("\n")
            current_blob = line
        else:
            current_blob += line
    if not any_matches:
        raise RuntimeError("No lines matched log header")
    if current_blob:
        yield current_blob.rstrip("\n")


def unique_lines(lines: Iterable[str]) -> Iterator[str]:
    """Yield only the first instance seen of any string in a sequence."""
    # yes this has been optimized, i promise
    seen: set[str] = set()
    for line in lines:
        if line not in seen:
            seen.add(line)
            yield line


def filter_lines(filter: str, lines: Iterable[str]) -> Iterator[str]:
    """Yield lines matching a pattern."""
    pattern = re.compile(filter)
    for line in lines:
        if pattern.search(line):
            yield line


def exclude_lines(filter: str, lines: Iterable[str]) -> Iterator[str]:
    """Yield lines not matching a pattern."""
    pattern = re.compile(filter)
    for line in lines:
        if not pattern.search(line):
            yield line


def output_lines(blobs: Iterable[str], filename: Optional[str] = None, append: bool = False) -> None:
    """Output log lines to stdout, or `filename` if passed."""
    file = None
    try:
        if filename:
            file = open(filename, "a" if append else "w")
        for blob in blobs:
            print(blob, file=file)
    finally:
        if file:
            file.close()


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        sys.exit(1)
