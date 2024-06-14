#!/usr/bin/env python3

import argparse
import fileinput
import json
import re
import statistics
import sys
from collections.abc import Iterable, Iterator
from dataclasses import asdict, dataclass
from datetime import datetime
from enum import Enum
from operator import attrgetter
from typing import Callable, Optional, cast

NaN = float("nan")

# I'm realizing that my pretty format perhaps does not make for a great
# regular expression
PATTERN = re.compile(
    r"""
    # start of line, one or more plus signs
    ^\++
    # A bracketed floating point number representing seconds since the unix epoch
    \[(?P<timestamp>\d+\.\d+)\]\s
    # A filename and a line number, separated by a colon, wrapped in parentheses
    \((?P<filename>(?:[^\\]|\\[^:])+)?:(?P<lineno>\d+)\):\s
    # an optional group consisting of a function name followed by a pair of
    # parentheses and a colon
    (?:(?P<function>[^|&;()<>\s]+)\(\):\s)?
    # everything else until the end of the line is the command
    (?P<command>.*)$
    """,
    re.VERBOSE | re.DOTALL,
)


@dataclass(order=True, frozen=True)
class ParsedLine:
    """A parsed line of input."""

    timestamp: datetime
    filename: str
    lineno: int
    function: Optional[str]
    command: str

    @property
    def location(self) -> str:
        return f"{self.filename}:{self.lineno}"


@dataclass(order=True, frozen=True)
class DeltaLine:
    """A parsed line with a time delta."""

    delta: float
    line: ParsedLine


@dataclass(order=True, frozen=True)
class DeltaAggregate:
    """An aggregate of related DeltaLines."""

    delta_sum: float
    delta_mean: float
    delta_median: float
    delta_stdev: float
    common: str
    lines: tuple[DeltaLine]

    def __init__(self, common: str, lines: Iterable[DeltaLine]):
        object.__setattr__(self, "common", common)
        object.__setattr__(self, "lines", tuple(sorted(lines)))

        if not self.lines:
            raise ValueError("lines may not be empty")

        # collect deltas excluding NaNs, unless NaN is the only value
        deltas = [line.delta for line in self.lines if line.delta != NaN] or [NaN]

        object.__setattr__(self, "delta_sum", sum(deltas))
        object.__setattr__(self, "delta_mean", statistics.mean(deltas))
        object.__setattr__(self, "delta_median", statistics.median(deltas))
        object.__setattr__(self, "delta_stdev", NaN if len(deltas) < 2 else statistics.stdev(deltas, self.delta_mean))

    @property
    def top_line(self) -> ParsedLine:
        return self.lines[0].line

    def __str__(self) -> str:
        fmt = "<8.6f"
        return (
            f"sum: {self.delta_sum:{fmt}} mean: {self.delta_mean:{fmt}} median: {self.delta_median:{fmt}} "
            f"stdev: {self.delta_stdev:{fmt}} ({len(self.lines):4d}): {self.common} {self.top_line.command!r}"
        )


class OutputFormat(Enum):
    """Enumeration of output formats."""

    LINES = "lines"
    JSON = "json"


LINES = OutputFormat.LINES
JSON = OutputFormat.JSON


def parse_absolute_lines(lines: Iterable[str]) -> Iterator[ParsedLine]:
    """Parse AbsoluteLines from an iterable of text lines."""

    lineiter = iter(lines)

    if (line := next(lineiter, None)) is None:
        return

    if not (capture := PATTERN.search(line)):
        raise ValueError("First line does not match", line)

    # All "logical" lines should match our regular expression. We occasionally
    # get physical lines that are either text output or commands with embedded
    # newlines, which do not match our regular expression. These physical lines
    # should be included in the "command" of most recent "logical" line. This
    # means we'll need to hold on to each "logical" line until either we detect
    # the start of the next logical line, or we exhaust our input.

    cmd_extra: list[str] = []

    while True:
        # we have a capture, but we don't know if its "complete" yet

        line = next(lineiter, None)

        if line is not None and not (nextcapture := PATTERN.search(line)):
            # got a new line, but it belongs to the current capture's `command`
            cmd_extra.append(line.rstrip())
            continue

        # either input has been exhausted, or we have the next logical line;
        # time to emit the current capture

        timestamp_str = capture.group("timestamp")
        timestamp = datetime.fromtimestamp(float(timestamp_str))
        filename = capture.group("filename")
        lineno = int(capture.group("lineno"))
        function = capture.group("function")
        command = capture.group("command").rstrip()
        command = "\n".join([command] + cmd_extra)

        yield ParsedLine(timestamp, filename, lineno, function, command)

        # now, did we exhaust our input?

        if line is None:
            break

        capture = cast(re.Match[str], nextcapture)
        cmd_extra = []


def calculate_deltas(lines: Iterable[ParsedLine]) -> Iterator[DeltaLine]:
    lines = iter(lines)
    try:
        prev = next(lines)
    except StopIteration:
        return

    for curr in lines:
        delta = curr.timestamp - prev.timestamp
        yield DeltaLine(delta.total_seconds(), prev)
        prev = curr

    yield DeltaLine(NaN, prev)


def aggregate_deltas(lines: Iterable[DeltaLine], keyfunc: Callable[[DeltaLine], str]) -> list[DeltaAggregate]:
    groups: dict[str, list[DeltaLine]] = {}
    for line in lines:
        groups.setdefault(keyfunc(line), []).append(line)

    return sorted([DeltaAggregate(key, group) for key, group in groups.items()])


def output_aggregates(aggregates: Iterable[DeltaAggregate], format: OutputFormat = LINES) -> None:
    if format is LINES:
        print("\n".join(str(agg) for agg in aggregates))
    elif format is JSON:
        json.dump(aggregates, sys.stdout, indent=2, default=asdict)
    else:
        raise ValueError("Invalid OutputFormat", format)


def main():

    parser = argparse.ArgumentParser(description="Collect timestamped log lines, and sort and display their durations")

    outformat = parser.add_mutually_exclusive_group()
    outformat.add_argument(
        "-j",
        "--json",
        dest="outformat",
        action="store_const",
        const=JSON,
        default=LINES,
        help="output a JSON list of objects",
    )

    parser.add_argument(
        "files", nargs="*", default=("-",), help="files to be read. `-` means stdin, which is the default"
    )

    args = parser.parse_args()
    delta_keyfunc = attrgetter("line.location")

    raw_lines = fileinput.input(args.files)
    abs_lines = parse_absolute_lines(raw_lines)
    delta_lines = calculate_deltas(abs_lines)
    aggregates = aggregate_deltas(delta_lines, delta_keyfunc)
    output_aggregates(aggregates, args.outformat)


if __name__ == "__main__":
    main()
