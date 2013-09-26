#!/usr/bin/env python
# vim: tw=78 sts=4 sw=4 et

from __future__ import print_function

import sys
import argparse
from os.path import basename

def mangle(text):
    return text.encode('rot-13').encode('base64').strip()

def unmangle(text):
    return text.decode('base64').decode('rot-13').strip()

def get_args():
    parser = argparse.ArgumentParser()
    parser.add_argument('-o', '--output', type=str,
            help='A file to be written to')
    parser.add_argument('-f', dest='file', help='''Indicates that command-line arguments are
            files to be read from''')
    parser.add_argument('text', nargs='*')

    return parser.parse_args()

def get_text(args):
    if args.file:
        text = ''
        for item in args.text:
            with open(item) as file:
                text += file.read()
    elif args.text:
        text = ' '.join(args.text)
    else:
        text = sys.stdin.read()

    return text

def main(argv):
    args = get_args()
    text = get_text(args)

    if basename(argv[0]) == 'mangle':
        output = mangle(text)
    elif basename(argv[0]) == 'unmangle':
        output = unmangle(text)

    if args.output:
        with open(args.output, 'w') as file:
            file.write(output)
    else:
        print(output)

if __name__ == '__main__':
    main(sys.argv)
