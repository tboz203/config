#!/usr/bin/env python3

"""
POC script for withtimestamps

read in data on stdin & prepend timestamps
"""

import datetime
import sys

def main():
    try:
        while True:
            line = sys.stdin.readline()
            if line == '':
                break
            now = datetime.datetime.now()
            print(f'{now}: {line}', end='')
    except (Exception, KeyboardInterrupt):
        pass


if __name__ == '__main__':
    main()

