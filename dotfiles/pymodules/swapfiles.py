#!/usr/bin/env python
"""List and clean up Neovim swap files."""

import argparse
import json
import re
import subprocess
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from typing import Optional

SHORT_HEADERS = [
    "number",
    "date",
    "exists",
    "filepath",
    "modified",
    "running",
]

WIDE_HEADERS = [
    # "swap_directory",
    "number",
    "swap_filepath",
    "owner",
    "date",
    "filepath",
    "exists",
    "modified",
    "username",
    "hostname",
    "process",
    "running",
]


class NotABool:
    """Constants that can't accidentally be evaluated as bools"""

    def __init__(self, name):
        self.name = name

    def __repr__(self):
        return f"{type(self)!r}({self.name!r})"

    __bool__ = None


# constants for argparse
YES = NotABool("YES")
NO = NotABool("NO")

# pattern used to split output into chunks
SPLIT_PAT = re.compile(
    r"""
    ^(?=    # zero-width match at start of line, followed by one of:
        \d+\.                           # a number and a dot
        | \s+In.(?:current.)?directory  # a directory header
        | \s+--.none.--                 # an empty swap entry list
    )
    """,
    re.MULTILINE | re.VERBOSE,
)

# pattern used to interpret output for a single swap file
SWAP_ENTRY_PAT = re.compile(
    r"""
    ^(?P<number>\d+)\.              # start of line, and the swap entry number
    \s*
    (?P<swap_filename>\S.*)         # one non-whitespace, and everything until end of line: the swap filename
    \n\s*
    owned.by:.(?P<owner>\S+)        # a WORD: edited file owner
    \s+
    dated:.(?P<date>\S.*)           # one non-whitespace, and everything until end of line: swapfile date
    \n\s*
    file.name:.(?P<filename>.*)     # everything until end of line: name of the edited file
    \n\s*
    modified:.(?P<modified>\w+)     # a word: is modified?
    \n\s*
    user.name:.(?P<username>\S+)    # a WORD: editor username
    \s+
    host.name:.(?P<hostname>\S+)    # a WORD: hostname
    \n\s*
    process.ID:.(?P<process>\d+)    # a number: process id
    \s?
    (?P<running>.*)                 # everything until end of line: still running?
    """,
    re.MULTILINE | re.VERBOSE,
)


@dataclass
class SwapEntry:
    """A class representing one swapfile"""

    # the directory the swapfile was found in
    swap_directory: Path
    # the position in the swapfile listing
    number: int
    # the path of the swapfile
    swap_filepath: Path
    # the owner of the swapfile (and hence the editor)
    owner: str
    # the modified time of the swapfile
    date: datetime
    # the path of the file being edited
    filepath: Path
    # whether the edited file still exists
    exists: bool
    # whether the swapfile contains modifications not in the file itself
    modified: bool
    # the owner of the file being edited
    username: str
    # the hostname
    hostname: str
    # the neovim process id
    process: int
    # whether the process is still running
    running: bool


def get_swapfile_listing():
    """Get a plaintext swapfile listing from nvim."""
    return subprocess.getoutput("nvim -L")


def parse_swapfile_listing(text):
    """Parse a plaintext swapfile listing into a list of SwapEntries."""
    chunks = SPLIT_PAT.split(text)
    directory: Optional[Path] = None
    swap_entries: list[SwapEntry] = []
    for chunk in chunks:
        chunk = chunk.strip()
        if chunk in {"Swap files found:", "-- none --"}:
            pass
        elif re.match(r"^In current directory:$", chunk):
            directory = Path(".")
        elif match := re.match(r"^In directory (\S.*):$", chunk):
            directory = Path(match.group(1)).expanduser()
        elif match := SWAP_ENTRY_PAT.match(chunk):
            groups = match.groupdict()
            if not directory:
                raise RuntimeError("directory listing not found")
            filepath = Path(groups["filename"])
            entry = SwapEntry(
                swap_directory=directory,
                number=int(groups["number"]),
                swap_filepath=directory.joinpath(groups["swap_filename"]),
                owner=groups["owner"],
                date=datetime.strptime(groups["date"], "%c"),
                filepath=filepath,
                exists=filepath.expanduser().exists(),
                modified=(groups["modified"] == "YES"),
                username=groups["username"],
                hostname=groups["hostname"],
                process=int(groups["process"]),
                running=bool(groups["running"]),
            )
            swap_entries.append(entry)
        else:
            raise RuntimeError("bad chunk!", chunk)

    return swap_entries


def filter_swap_entries(
    swap_entries: list[SwapEntry],
    /,
    *,
    exists: Optional[NotABool] = None,
    modified: Optional[NotABool] = None,
    running: Optional[NotABool] = None,
) -> list[SwapEntry]:
    """
    Filter a list of swap entries based on certain criteria.
    An entry is included if it passes ALL filters.
    """
    output: list[SwapEntry] = []
    for entry in swap_entries:
        if exists is YES and not entry.exists:
            continue
        elif exists is NO and entry.exists:
            continue

        if modified is YES and not entry.modified:
            continue
        elif modified is NO and entry.modified:
            continue

        if running is YES and not entry.running:
            continue
        elif running is NO and entry.running:
            continue

        output.append(entry)

    return output


def report_swap_entries(
    swap_entries: list[SwapEntry], /, *, wide: bool = False, as_json: bool = False, delete: bool = False
) -> None:
    """Report selected swap entries, and possibly delete them."""
    if delete:
        for entry in swap_entries:
            entry.swap_filepath.unlink()

    if as_json:
        # swap_entry_dicts = [asdict(entry) | {"deleted": delete} for entry in swap_entries]
        headers = WIDE_HEADERS if wide else SHORT_HEADERS
        swap_entry_dicts = [{header: getattr(entry, header) for header in headers} for entry in swap_entries]
        swap_entry_dicts = [item | {"deleted": delete} for item in swap_entry_dicts]
        print(json.dumps(swap_entry_dicts, indent=2, default=_encode_more_types))
    else:
        print(format_swap_entry_list(swap_entries))
        if delete:
            print("Swap files deleted")


def format_swap_entry_list(swap_entries: list[SwapEntry], wide: bool = False) -> str:
    headers = WIDE_HEADERS if wide else SHORT_HEADERS
    rows = [headers]

    for entry in swap_entries:
        row = [getattr(entry, header) for header in headers]
        rows.append(row)

    column_widths = [max(len(str(item)) for item in column) for column in zip(*rows)]
    lines = [" | ".join("{!s:{}}".format(item, width) for item, width in zip(row, column_widths)) for row in rows]
    return "\n".join(lines)


def _encode_more_types(obj):
    """Encode more Python types into JSON. Not necessarily reversible"""
    if isinstance(obj, datetime):
        return obj.isoformat()
    if isinstance(obj, Path):
        return obj.as_posix()
    raise TypeError(f"Can't encode {obj!r} ({type(obj)})")


def get_args(argv: Optional[list[str]] = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)

    exists_group = parser.add_mutually_exclusive_group()
    exists_group.add_argument(
        "-e",
        "--exists",
        action="store_const",
        const=YES,
        dest="exists",
        help="only report swapfiles whose file still exists",
    )
    exists_group.add_argument(
        "-E",
        "--not-exists",
        action="store_const",
        const=NO,
        dest="exists",
        help="only report swapfiles whose file does not exist",
    )

    modified_group = parser.add_mutually_exclusive_group()
    modified_group.add_argument(
        "-m",
        "--modified",
        action="store_const",
        const=YES,
        dest="modified",
        help="only report swapfiles who contain modifications",
    )
    modified_group.add_argument(
        "-M",
        "--not-modified",
        action="store_const",
        const=NO,
        dest="modified",
        help="only report swapfiles who do not contain modifications",
    )

    running_group = parser.add_mutually_exclusive_group()
    running_group.add_argument(
        "-r",
        "--running",
        action="store_const",
        const=YES,
        dest="running",
        help="only report swapfiles marked as `running`",
    )
    running_group.add_argument(
        "-R",
        "--not-running",
        action="store_const",
        const=NO,
        dest="running",
        help="only report swapfiles not marked as `running`",
    )

    parser.add_argument("-w", "--wide", action="store_true", help="output more columns")
    parser.add_argument("-j", "--json", action="store_true", help="output in JSON format")
    parser.add_argument("-d", "--delete", action="store_true", help="delete reported swapfiles")

    return parser.parse_args(argv)


def main():
    args = get_args()
    listing = get_swapfile_listing()
    swap_entries = parse_swapfile_listing(listing)
    swap_entries = filter_swap_entries(swap_entries, exists=args.exists, modified=args.modified, running=args.running)
    report_swap_entries(swap_entries, wide=args.wide, as_json=args.json, delete=args.delete)


if __name__ == "__main__":
    main()
