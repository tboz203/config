#!/usr/bin/env python

import sys, re
import readline
import rlcompleter
import shutil
import traceback
from pprint import pprint, pformat

try:
    import builtins
except ImportError:
    builtins = __builtins__


def get_columns():
    if hasattr(shutil, 'get_terminal_size'):
        return shutil.get_terminal_size().columns
    return 80


def show(*args, **kwargs):
    if 'width' not in kwargs:
        kwargs['width'] = get_columns() - 1
    pprint(*args, **kwargs)


def _displayhook(value):
    if value is None:
        return
    builtins._ = None
    text = pformat(value, width=get_columns())
    try:
        sys.stdout.write(text)
    except UnicodeEncodeError:
        bytes_ = text.encode(sys.stdout.encoding, 'backslashreplace')
        if hasattr(sys.stdout, 'buffer'):
            sys.stdout.buffer.write(bytes_)
        else:
            text = bytes_.decode(sys.stdout.encoding, 'strict')
            sys.stdout.write(text)
    sys.stdout.write("\n")
    builtins._ = value


def _excepthook(exc_type, exc_value, exc_traceback):
    builtins._ = None
    text = ''.join(traceback.format_exception(
            exc_type, exc_value, exc_traceback))
    try:
        sys.stderr.write(text)
    except UnicodeEncodeError:
        bytes_ = text.encode(sys.stderr.encoding, 'backslashreplace')
        if hasattr(sys.stderr, 'buffer'):
            text = bytes_.decode(sys.stderr.encoding, 'strict')
            sys.stderr.write(text)
    builtins._ = exc_value


sys.displayhook = _displayhook
sys.excepthook = _excepthook
