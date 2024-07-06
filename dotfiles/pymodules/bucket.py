#!/usr/bin/env python
# 2013-05-15
# Tommy Bozeman (tboz203)
# refactor of an earlier script
# "quick python script written to deal w/ frustrations w/ uniq."

# I'm looking at doing some more complicated stuff with args, atm. I think this
# might be something to look at using argparse with. we can do like:
#   -d: print only duplicated items
#   -u: print only unique items
#   -c: print count for each item
#   -n: sort by count
#   -a: sort alphabetical
#   -r: reverse order

# do we want to try and do fields? it'd be nice... we'll see, lol

# non-option args are files to be read from. '-' signifies stdin, as does
# having no files specified.

"""
Put input lines into buckets.

By default, simply copy lines from each input to stdout.
"""

from __future__ import print_function

import argparse
import fileinput
import json
import sys
from collections import Counter
from operator import itemgetter


def parse_arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)

    parser.add_argument("-c", "--count", action="store_true", help="prefix each item with its count")
    parser.add_argument("-r", "--reverse", action="store_true", help="reverse order")
    parser.add_argument(
        "files",
        nargs="*",
        default=["-"],
        help="the list of files to read in. '-' (stdin) by default",
    )

    sort_group = parser.add_mutually_exclusive_group()
    sort_group.add_argument("-a", "--alphabetical", action="store_true", help="sort output alphabetically")
    sort_group.add_argument(
        "-n",
        "--numeric",
        action="store_true",
        help="sort output by number of occurences",
    )

    show_group = parser.add_mutually_exclusive_group()
    show_group.add_argument("-d", "--duplicated", action="store_true", help="show only duplicated items")
    show_group.add_argument("-u", "--unique", action="store_true", help="show only unique items")

    parser.add_argument("-j", "--json", action="store_true", help="output json")

    return parser.parse_args()


def get_counts(files: list[str]) -> list[tuple[str, int]]:
    lines = list(fileinput.input(files))
    counter = Counter([line.strip("\n") for line in lines])
    return list(counter.items())


def output(args, counts: list[tuple[str, int]]) -> None:
    if args.unique:
        # items = filter((lambda x: x[1] == 1), items)
        counts = [(line, count) for line, count in counts if count == 1]
    elif args.duplicated:
        # counts = filter((lambda x: x[1] != 1), counts)
        counts = [(line, count) for line, count in counts if count != 1]

    if not counts:
        return

    if args.alphabetical:
        # sorts by line, then by count
        counts.sort()
    elif args.numeric:
        # sorts by count, preserving order otherwise
        counts.sort(key=itemgetter(1))

    if args.reverse:
        counts.reverse()

    if args.json:
        if args.count:
            print(json.dumps([(count, line) for line, count in counts], indent=2))
        else:
            print(json.dumps([line for line, _ in counts], indent=2))
        return

    if args.count:
        largest_count = max([count for _, count in counts])
        width = len(str(largest_count)) + 1
        for line, count in counts:
            print(f"{count:>{width}}: {line}")
    else:
        for line, _ in counts:
            print(line)


def stream_output(files: list[str], unique: bool, duplicated: bool) -> None:
    """Stream our output as we receive it."""

    if unique and duplicated:
        raise ValueError("Cannout output only unique lines and only duplicated lines simultaneously")

    if unique:
        seen = set()
        for line in fileinput.input(files):
            line = line.removesuffix("\n")
            linehash = hash(line)
            if linehash in seen:
                continue
            seen.add(linehash)
            print(line)
    elif duplicated:
        once = set()
        twice = set()
        for line in fileinput.input(files):
            line = line.removesuffix("\n")
            linehash = hash(line)
            if linehash in twice:
                continue
            if linehash in once:
                print(line)
                twice.add(linehash)
                continue
            once.add(linehash)
    else:
        for line in fileinput.input(files):
            print(line.removesuffix("\n"))


def main() -> None:
    args = parse_arguments()
    try:
        if args.count or args.reverse or args.alphabetical or args.numeric or args.json:
            counts = get_counts(args.files)
            output(args, counts)
        else:
            stream_output(args.files, args.unique, args.duplicated)
    except KeyboardInterrupt as exc:
        return exc


if __name__ == "__main__":
    sys.exit(main())
