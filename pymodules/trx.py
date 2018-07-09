#!/usr/bin/env python
# 2012/12/05 - tboz203

# going back through this script, trying to figure out what it does. I feel
# like what it's supposed to do is replace html-escaped characters...

from __future__ import print_function

import re
import sys

regex = re.compile(r'%(\w{2})')

def replfunc(match):
    val = match.group(1)
    val = chr(int(val, 16))
    return val

def extract(line):
    return regex.subn(replfunc, line)[0]

if __name__ == '__main__':
    for arg in sys.argv[1:]:
        print(extract(arg))
