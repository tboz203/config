#!/usr/bin/env python
'''sort logs by timestamp (as long as its the first field)'''

import fileinput
import re

def main() -> None:
    lines = get_lines()
    lines = sort_logs(lines)
    print(''.join(lines))

def get_lines() -> list[str]:
    return list(fileinput.input())

def sort_logs(lines: list[str]) -> list[str]:
    pattern = re.compile('^\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d(\.\d{1,9})?')

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
