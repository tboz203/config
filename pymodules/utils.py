# pylint: disable=missing-docstring

import collections as _collections
import datetime as _datetime
import functools as _functools
import getpass as _getpass
import itertools as _itertools
import os as _os
import warnings as _warnings
import shutil as _shutil

from pprint import pprint as _pprint

SI_SUFFIXES = ['K', 'M', 'G', 'T', 'P', 'E', 'Z', 'Y']


def green(text):
    return "\x1b[0;32m%s\x1b[0m" % text

def red(text):
    return "\x1b[1;31m%s\x1b[0m" % text

def yellow(text):
    return "\x1b[1;33m%s\x1b[0m" % text

def clear():
    print("\x1b[2J\x1b[f", end='')


def format_timedelta(delta, use_suffix=True):    # pylint: disable=too-many-branches
    if not isinstance(delta, _datetime.timedelta):
        raise ValueError("need instance of datetime.timedelta, not %s" %
                         type(delta))
    if delta > _datetime.timedelta(0):
        suffix = "from now"
        prefix = ""
    else:
        suffix = "ago"
        prefix = "-"
    delta = abs(delta)
    if delta.days > 365 * 2:
        timestr = "{} years".format(delta.days // 365)
    elif delta.days > 365:
        timestr = "a year"
    elif delta.days > 30 * 2:
        timestr = "{} months".format(delta.days // 30)
    elif delta.days > 30:
        timestr = "a month"
    elif delta.days > 7 * 2:
        timestr = "{} weeks".format(delta.days // 7)
    elif delta.days > 7:
        timestr = "a week"
    elif delta.days > 1:
        timestr = "{} days".format(delta.days)
    elif delta.seconds > 60 * 60 * 2:
        timestr = "{} hours".format(delta.seconds // 3600 + delta.days * 24)
    elif delta.seconds > 60 * 2:
        timestr = "{} minutes".format(delta.seconds // 60)
    else:
        timestr = "{} seconds".format(delta.seconds)

    if use_suffix:
        timestr = timestr + " " + suffix
    else:
        timestr = prefix + timestr

    return timestr


def time_since(datetime, utc=True):
    if utc:
        now = _datetime.datetime.utcnow()
    else:
        now = _datetime.datetime.now()
    return format_timedelta(datetime - now)


def color_time_since(datetime, utc=True):
    if utc:
        now = _datetime.datetime.utcnow()
    else:
        now = _datetime.datetime.now()

    delta = datetime - now
    if abs(delta) < _datetime.timedelta(0, 60*60):
        colorfunc = red
    elif abs(delta) < _datetime.timedelta(1, 0):
        colorfunc = yellow
    elif abs(delta) < _datetime.timedelta(7):
        colorfunc = green
    else:
        colorfunc = lambda d: d

    return colorfunc(format_timedelta(delta))

# these next two functions use "1 kilobyte == 1024 bytes, etc." i think that's
# actually incorrect (1 kilobyte == 1000 bytes, etc.), but i don't care.

def humanize(num):
    # uses side-effects of iterating through a collection to select the
    # correct suffix
    for suffix in [''] + SI_SUFFIXES:
        if num > 1024:
            num /= 1024
        else:
            break

    return "{:.2f}{:}".format(num, suffix)        # pylint: disable=undefined-loop-variable

def dehumanize(num):
    factor = 1
    suffix = num[-1].upper()
    # may have '100B' or '24KB', etc
    if suffix == 'B':
        num = num[:-1]
        suffix = num[-1].upper()
    if suffix in SI_SUFFIXES:
        factor = 2 ** (10 * (SI_SUFFIXES.index(suffix) + 1))
        # eg, 'K' -> 2 ** (10 * 1); G -> 2 ** (10 * 3)
    # if this throws an exception, let it propagate
    return float(num[:-1]) * factor


def get_creds(env_prefix=None):
    '''get user credentials.

    if `env_prefix` is provided, look for environment variables matching
    "%s_USER" and "%s_PASSWORD". if `env_prefix` is not provided, or if
    matching environment variables do not exist, interactively request
    credentials from the user.'''

    user, pw = None, None
    if env_prefix:
        user_var = '%s_USER' % env_prefix
        pw_var = '%s_PASSWORD' % env_prefix
        if user_var in _os.environ and pw_var in _os.environ:
            user = _os.environ[user_var]
            pw = _os.environ[pw_var]
        else:
            _warnings.warn('Credential environment variables not found: %s, %s'
                          % (user_var, pw_var))

    if not (user and pw):
        user_guess = _getpass.getuser()
        user = input('Username [%s]: ' % user_guess) or user_guess
        pw = _getpass.getpass()
        if not pw:
            raise ValueError('No password supplied')

    return (user, pw)


def columnize(alist, yfirst=True, width=None):
    roundup = lambda f: - int(f // -1)
    width = width or _os.get_terminal_size().columns - 2
    alist = list(map(str, alist))

    # process is: divide list into two columns. check to see if columns will
    # fit to screen. if yes, increase number of columns & try again. if no,
    # reduce number of columns (minimum 1 b/c we start with 2) and print to
    # screen

    def get_columns(alist, numcol):
        if yfirst:
            height = roundup(len(alist) / numcol)
            columns = [alist[(i*height):((i+1)*height)] for i in range(numcol)]
        else:
            columns = [alist[i::numcol] for i in range(numcol)]

        columns = [c for c in columns if c]

        # length of longest word in each column.
        c_widths = [max(len(word) for word in col) for col in columns]

        return columns, c_widths

    numcol = 1
    while True:

        columns, c_widths = get_columns(alist, numcol + 1)

        # check columns
        textwidth = sum(c_widths)
        paddingwidth = 2 * (len(columns))
        if (textwidth + paddingwidth + 1) >= width:
            break

        numcol += 1

    columns, c_widths = get_columns(alist, numcol)

    lines = []
    for line in _itertools.zip_longest(*columns, fillvalue=""):
        out = []
        for i, word in enumerate(line):
            out.append(word.ljust(c_widths[i]))
        lines.append("  ".join(out))

    return lines


def print_columns(alist, yfirst=True, width=None):
    print("\n".join(columnize(alist, yfirst, width)))


def walk_xml(elem, depth=None):
    if depth == 0:
        return elem
    children = elem.getchildren()
    if not children:
        return elem
    if depth is not None:
        depth -= 1
    return (elem, [walk_xml(c, depth) for c in children])


def show(*args, **kwargs):
    if 'width' not in kwargs:
        kwargs['width'] = _shutil.get_terminal_size().columns
    _pprint(*args, **kwargs)


def group_by(collection, keyfunc):
    grouped = _collections.defaultdict(list)
    for item in collection:
        grouped[keyfunc(item)].append(item)
    return dict(grouped)


def compose(*functions):
    compose2 = lambda f, g: lambda *args, **kwargs: f(g(*args, **kwargs))
    return _functools.reduce(compose2, functions)
