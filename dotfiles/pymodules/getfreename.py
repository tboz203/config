import os
import re

# trying to do all this w/ regular expressions
rstr = r"(.*?)(_\d{2})?(\.[^/]*)?$"
regex = re.compile(rstr)


def getfreename(filename):
    if not os.path.exists(filename):
        return filename
    names = regex.search(filename).groups()
    tail = names[2] if names[2] else ""
    fstring = names[0] + "_{:02d}" + tail
    for i in range(2, 99):
        trial = fstring.format(i)
        if not os.path.exists(trial):
            return trial

    raise ValueError("Cowardly refusing to make more", filename)
