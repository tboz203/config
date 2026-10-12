from __future__ import annotations

import re
from os import PathLike
from pathlib import Path

pattern = re.compile(r"(.*?)(_\d{2})?(\.[^/]*)?$")


def getfreename(filename: Path | PathLike[str]) -> Path:
    """Given the name of a file that may or may not exist, return a filename
    that *does not* currently exist."""
    filename = Path(filename)
    if not filename.parent.exists():
        raise FileNotFoundError(filename.parent)
    if not filename.exists():
        return filename
    assert (match := pattern.search(str(filename)))
    names = match.groups()
    tail = names[2] or ""
    fstring = names[0] + "_{:02d}" + tail
    for i in range(2, 99):
        trial = Path(fstring.format(i))
        if trial.exists():
            continue
        return trial

    raise FileExistsError(1, "Cowardly refusing to make more", filename)
