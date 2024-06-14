#!/usr/bin/env python3

import argparse
import fileinput
import json
import re
from collections.abc import Iterable, Iterator
from dataclasses import asdict, dataclass
from datetime import datetime
from enum import Enum

from dateutil import parser


@dataclass(order=True)
class AbsoluteLine:
    """A line with an absolute timestamp"""

    timestamp: datetime
    line: str


@dataclass(order=True)
class DeltaLine:
    """A pair of lines with a timestamp delta"""

    delta: float
    before: str
    after: str


class OutputFormat(Enum):
    """Enumeration of output formats."""

    BEFORE = "before"
    AFTER = "after"
    JSON = "json"


BEFORE = OutputFormat.BEFORE
AFTER = OutputFormat.AFTER
JSON = OutputFormat.JSON


def parse_absolute_lines(lines: Iterable[str], pattern: re.Pattern) -> Iterator[AbsoluteLine]:
    # TODO: use format

    matched_count = 0
    missed_count = 0
    for line in lines:
        if not (capture := pattern.search(line)):
            missed_count += 1
            continue
        matched_count += 1
        timestamp_str = capture.group(1)
        try:
            timestamp = datetime.fromtimestamp(float(timestamp_str))
        except ValueError:
            timestamp = parser.parse(capture.group(1))
        yield AbsoluteLine(timestamp, line.rstrip())


def calculate_deltas(lines: Iterable[AbsoluteLine]) -> Iterator[DeltaLine]:
    lines = iter(lines)
    # allow any StopIteration here to propagate
    prev = next(lines)

    for curr in lines:
        delta = curr.timestamp - prev.timestamp
        yield DeltaLine(delta.total_seconds(), prev.line, curr.line)
        prev = curr


def display(deltas: Iterable[DeltaLine], format: OutputFormat = BEFORE) -> None:
    deltas = list(deltas)
    if not deltas:
        return
    if format in (BEFORE, AFTER):
        # a list of (delta_seconds, line) pairs
        output_parts: list[tuple[float, str]] = []
        if format is BEFORE:
            # if we compare each line to the line before, the line-in-question is
            # the one after, and vice versa
            output_parts += [(0, deltas[0].before)]
            output_parts += [(item.delta, item.after) for item in deltas]
        else:
            output_parts += [(item.delta, item.before) for item in deltas]
            output_parts += [(0, deltas[-1].after)]
        output_parts.sort()
        output_lines = [f"{seconds:.6f} {line}" for seconds, line in output_parts]
        print("\n".join(output_lines))
    elif format is JSON:
        deltas.sort()
        delta_dicts = [asdict(item) for item in deltas]
        print(json.dumps(delta_dicts, indent=2))
    else:
        raise ValueError("Invalid format", format)


def main():

    parser = argparse.ArgumentParser(description="Collect timestamped log lines, and sort and display their durations")

    parser.add_argument(
        "-f",
        "--format",
        default=r"^(.*): ",
        help="A regular expression used to extract a timestamp",
    )

    outformat = parser.add_mutually_exclusive_group()
    outformat.add_argument(
        "-b",
        "--before",
        dest="outformat",
        action="store_const",
        const=BEFORE,
        default=AFTER,
        help="output each line with the delta of the line before it (NOT the `before` lines from JSON)",
    )
    outformat.add_argument(
        "-a",
        "--after",
        dest="outformat",
        action="store_const",
        const=AFTER,
        help="output each line with the delta of the line after it (NOT the `after` lines from JSON)",
    )
    outformat.add_argument(
        "-j",
        "--json",
        dest="outformat",
        action="store_const",
        const=JSON,
        help='output a JSON list of objects, with attributes "before", "after", and "delta"',
    )

    parser.add_argument(
        "files", nargs="*", default=("-",), help="files to be read. `-` means stdin, which is the default"
    )
    args = parser.parse_args()

    try:
        pattern = re.compile(args.format)
    except re.error as exc:
        parser.error(f"Format error: {exc}")

    if pattern.groups != 1:
        parser.error("Format error: regular expression should define exactly one group")

    raw_lines = fileinput.input(args.files)
    abs_lines = parse_absolute_lines(raw_lines, pattern)
    delta_lines = calculate_deltas(abs_lines)
    display(delta_lines, args.outformat)


if __name__ == "__main__":
    main()
