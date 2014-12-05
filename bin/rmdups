#!/usr/bin/env python

from __future__ import print_function

import os
from sys import argv
from hashlib import sha256

def main(names):
    hashes = set()

    for name in names:
        filehash = hash_file(name)
        if filehash in hashes:
            print('removing', name)
            os.remove(name)
        else:
            hashes.add(filehash)


def hash_file(name):
    with open(name) as f:
        data = f.read()
    return sha256(data).hexdigest()

if __name__ == '__main__':
    main(argv[1:])
