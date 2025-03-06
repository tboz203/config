#!/usr/bin/env python3

import argparse
import fileinput
import json
import math
import re
import statistics
import sys
from collections.abc import Iterable, Iterator
from dataclasses import asdict, dataclass, is_dataclass
from datetime import datetime, timedelta
from enum import Enum
from operator import attrgetter
from typing import Callable, Optional, Self, cast

NaN = float("nan")

PATTERN = re.compile(
    r"""
    # start of line, one or more plus signs, and optional whitespace
    ^(?P<depth>\++)\s*
    # A bracketed floating point number representing seconds since the unix epoch
    \[(?P<timestamp>\d+\.\d+)\]\s
    # the start of a parenthesized group
    \(
    # a filename (without colons) followed by a colon
    (?P<filename>[^:]+):
    # a linenumber
    (?P<lineno>\d+)
    # an optional group consisting of a colon, a function name, and a pair of parentheses
    (?::(?P<function>[^|&;()<>\s]+))?
    # the end of the parenthesized group, followed by a colon and whitespace
    \):\s+
    # everything else until the end of the line is the command
    (?P<command>.*)$
    """,
    re.VERBOSE | re.DOTALL,
)


@dataclass(frozen=True)
class LogLine:
    """A parsed log line."""

    depth: int
    timestamp: datetime
    filename: str
    lineno: int
    function: Optional[str]
    command: str

    @property
    def location(self) -> str:
        return f"{self.filename}:{self.lineno}"


@dataclass(frozen=True)
class DeltaLine(LogLine):
    """A parsed log line with a time delta."""

    delta: float


@dataclass(frozen=True)
class CallTree(DeltaLine):
    """A call tree parsed from delta lines."""

    nodes: tuple[DeltaLine | Self, ...]


@dataclass(order=True, frozen=True)
class DeltaAggregate:
    """An aggregate of related DeltaLines."""

    delta_sum: float
    delta_mean: float
    delta_median: float
    delta_stdev: float
    common: str
    lines: tuple[DeltaLine, ...]

    def __init__(self, common: str, lines: Iterable[DeltaLine]):
        object.__setattr__(self, "common", common)
        object.__setattr__(self, "lines", tuple(sorted(lines, key=attrgetter("delta"))))

        if not self.lines:
            raise ValueError("lines may not be empty")

        # collect deltas excluding NaNs, unless NaN is the only value
        deltas = [line.delta for line in self.lines if line.delta != NaN] or [NaN]

        object.__setattr__(self, "delta_sum", sum(deltas))
        object.__setattr__(
            self,
            "delta_mean",
            NaN if NaN in deltas else statistics.geometric_mean(deltas),
        )
        object.__setattr__(self, "delta_median", statistics.median(deltas))
        object.__setattr__(
            self,
            "delta_stdev",
            NaN if len(deltas) < 2 else statistics.stdev(deltas, self.delta_mean),
        )

    @property
    def top_line(self) -> DeltaLine:
        return self.lines[-1]

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


def stripansi(text: str) -> str:
    text = re.sub(r"\x01[^\0x02]*\x02", "", text)
    text = re.sub(r"\x1b\[[^a-zA-Z]*[a-zA-Z]", "", text)
    return text


def parse_absolute_lines(lines: Iterable[str]) -> Iterator[LogLine]:
    """Parse AbsoluteLines from an iterable of text lines."""

    lineiter = iter(lines)

    if (line := next(lineiter, None)) is None:
        return

    line = stripansi(line.rstrip())

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
        nextcapture = None

        if line is not None:
            line = stripansi(line.rstrip())
            if not (nextcapture := PATTERN.search(line)):
                # got a new line, but it belongs to the current capture's `command`
                cmd_extra.append(line)
                continue

        # either input has been exhausted, or we have the next logical line;
        # either way, time to emit the current capture

        depth = len(capture.group("depth"))
        timestamp = datetime.fromtimestamp(float(capture.group("timestamp")))
        filename = capture.group("filename")
        lineno = int(capture.group("lineno"))
        function = capture.group("function")
        command = capture.group("command").rstrip()
        command = "\n".join([command] + cmd_extra)

        yield LogLine(depth, timestamp, filename, lineno, function, command)

        # now, did we exhaust our input?

        if line is None:
            break

        capture = cast(re.Match[str], nextcapture)
        cmd_extra = []


def calculate_deltas(lines: Iterable[LogLine]) -> Iterator[DeltaLine]:
    lines = iter(lines)
    try:
        prev = next(lines)
    except StopIteration:
        return

    # yield DeltaLine(NaN, prev)

    for curr in lines:
        delta = curr.timestamp - prev.timestamp
        # yield DeltaLine(delta.total_seconds(), curr)
        yield DeltaLine(**asdict(prev), delta=delta.total_seconds())
        prev = curr

    yield DeltaLine(**asdict(prev), delta=NaN)


def build_call_tree(
    top_line: DeltaLine, lines: Iterable[DeltaLine]
) -> tuple[CallTree, DeltaLine | None, Iterator[DeltaLine]]:
    """
    Build a call tree from delta lines.

    returns 1) the built call tree, 2) the next top line (if any), and 3) any
    further remaining lines.
    """
    # Trying to figure out 1) what I want, and 2) what that looks like
    # maybe instead of starting at the top, i should start at the bottom?
    # what's the simplest case? A single delta line? or a call tree with no
    # nested trees? if the output is a call tree with multiple delta lines but
    # no nested trees, what did the input look like? In order to populate the
    # tree itself, we need that one line at depth = N, and then we need all the
    # following lines at depth = N-1. Further, in order to know where to stop,
    # we'll have to take off one more line that we use, which we'll then have
    # to return as well. So: we ask for that top line and all the lines after
    # it; we look at lines one by one until we find one at the same level as
    # our top line (or until we run out), and then give that and the remainder
    # back.
    #
    # 1) should we recurse when depth < N-1?
    # 2) how would we handle the top-level tree? is it possible with `CallTree` the shape it is?

    lines = iter(lines)
    nodes = []
    while True:
        line = next(lines)


def aggregate_deltas(
    lines: Iterable[DeltaLine], keyfunc: Callable[[DeltaLine], str]
) -> list[DeltaAggregate]:
    groups: dict[str, list[DeltaLine]] = {}
    for line in lines:
        groups.setdefault(keyfunc(line), []).append(line)

    return sorted([DeltaAggregate(key, group) for key, group in groups.items()])


def output_aggregates(
    aggregates: Iterable[DeltaAggregate], format: OutputFormat = LINES
) -> None:
    if format is LINES:
        print("\n".join(str(agg) for agg in aggregates))
    elif format is JSON:
        json.dump(
            aggregates, sys.stdout, indent=2, allow_nan=False, default=json_default
        )
        # json.dump(aggregates, sys.stdout, indent=2, default=json_default)
    else:
        raise ValueError("Invalid OutputFormat", format)


def json_default(obj):
    if isinstance(obj, float) and not math.isfinite(obj):
        return None
    if isinstance(obj, datetime):
        return obj.isoformat()
    if isinstance(obj, timedelta):
        return obj.total_seconds()
    if is_dataclass(obj) and not isinstance(obj, type):
        return asdict(obj)
    raise TypeError("lol what is this", obj)


def main():
    parser = argparse.ArgumentParser(
        description="Collect timestamped log lines, and sort and display their durations"
    )

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
        "files",
        nargs="*",
        default=("-",),
        help="files to be read. `-` means stdin, which is the default",
    )

    args = parser.parse_args()
    delta_keyfunc = attrgetter("location")

    raw_lines = fileinput.input(args.files)
    abs_lines = parse_absolute_lines(raw_lines)
    delta_lines = calculate_deltas(abs_lines)
    aggregates = aggregate_deltas(delta_lines, delta_keyfunc)
    output_aggregates(aggregates, args.outformat)


if __name__ == "__main__":
    main()
