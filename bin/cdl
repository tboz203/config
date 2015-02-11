#!/usr/bin/env python

# I just realized that this makes no guarantee that it doesn't overwrite files
# i'm going to have to go through this and set it up to re-name files that
# already exist at the destination. until then, do it by hand i suppose.
# =================
# 2012/08/11
# just refactored our datastructs. now using for-loops and dicts to make the
# code a bit more simplified. send() is still ugly, but whatever.
# =================
# 2012/8/27
# just had an idea: need to add section to this checking to see if truecrypt is
# mounted, and if so, move files in downloads and in vids there, checking for
# name collision. prolly not going to do it now, b/c it's 1 am.
# =================
# 2013/02/02
# added the truecrypt section, and streamlined the code a bit.
# =================
# 2013/04/07
# going to attempt to refactor the naming process
# =================
# 2013-05-02
# It seems when i refactored the naming process, i didn't really finish it.
# also: fixed a bug that resulted in _03_01.mp4 issues.

from __future__ import print_function
import os
import re
from sys import argv
from shutil import move
from getfreename import getfreename

# our important directories
targets = ['/home/tommy/dloads/',
           '/win/cygwin/home/Tommy/',
           '/win/Users/Tommy/Downloads/']

# our different targets and destinations
places = {'img': '/home/tommy/media/pics/',
          'aud': '/home/tommy/media/music/',
          'vid': '/home/tommy/dloads/vids/',
          'gif': '/home/tommy/media/pics/gifs/',
          'tor': '/home/tommy/dloads/keys/'}

# a quick dictionary of file extensions we're interested in
types = {'img': ('jpg', 'png', 'bmp', 'jpeg', 'tiff', 'gif', 'svg', 'xcf'),
         'aud': ('aac', 'mp3', 'm4a', 'ogg', 'wma', 'flac'),
         'vid': ('mp4', 'flv', 'wmv', 'mpg', 'avi', 'mov', 'm4v', 'f4v'),
         'gif': ('gif',),
         'tor': ('torrent',)}

def say(str):
    if __debug__:
        print(str)

def check(filename):
    '''If it's not there, make it (for directories)'''
    if not os.path.isdir(filename):
        os.mkdir(filename)

def gettype(filename):
    '''Get the file's type, as per our dictionary'''
    ext = filename[filename.rfind('.') + 1:].lower()
    for key in types:
        if ext in types[key]:
            return key

def send(filename, path):
    '''Move a file. make sure the new name is free. print a notice to screen
    telling what went where.'''
    oldname = os.path.abspath(filename)
    newname = getfreename(path + filename)
    say('='*80)
    say('renaming {}\nto       {}'.format(oldname, newname))
    move(oldname, newname)

def main():
    global targets

    for arg in argv:
        if os.path.isdir(arg):
            targets += [os.path.abspath(arg)]
    for target in targets:
        if not os.path.isdir(target):
            continue
        os.chdir(target)
        for item in sorted(os.listdir('.')):
            type = gettype(item)
            if type in places:
                check(places[type])
                send(item, places[type])

if __name__ == '__main__':
    main()
