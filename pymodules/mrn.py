#!/usr/bin/env python

from __future__ import print_function
from os import path
from sys import argv, stderr
from shutil import move
from getfreename import getfreename

def move_rename(oldname, newname):
    oldname = oldname.rstrip('/')
    newname = newname.rstrip('/')
    if path.isdir(newname):
        newname = newname + '/' + path.basename(oldname)
    newname = getfreename(newname)
    print(oldname,' -> ', newname)
    move(oldname, newname)

def main():
    if len(argv) < 3:
        print("[-] I'm not sure what to do with this...", file=stderr)
    for item in argv[1:-1]:
        move_rename(item, argv[-1])

if __name__ == '__main__':
    main()
