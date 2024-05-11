# pylint: disable=missing-docstring

import getpass
import inspect
import json
import math
import os
import shlex
import subprocess
import timeit
import warnings
from datetime import datetime, timedelta
from decimal import Decimal
from functools import reduce
from itertools import zip_longest
from pprint import pprint
from shutil import get_terminal_size
from textwrap import dedent

SI_SUFFIXES = ["K", "M", "G", "T", "P", "E", "Z", "Y"]


def noop(arg):
    """Do nothing."""
    return arg


def red(text):
    return "\x1b[1;31m%s\x1b[0m" % text


def green(text):
    return "\x1b[0;32m%s\x1b[0m" % text


def yellow(text):
    return "\x1b[1;33m%s\x1b[0m" % text


def clear():
    print("\x1b[2J\x1b[f", end="")


def format_timedelta(delta, use_suffix=True):  # pylint: disable=too-many-branches
    """Human-friendly timdelta formatting."""
    if not isinstance(delta, timedelta):
        raise ValueError("need instance of datetime.timedelta, not %s" % type(delta))
    if delta > timedelta(0):
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


def time_since(timestamp, utc=True):
    now = datetime.now()
    if utc:
        now = now.astimezone()
    return format_timedelta(timestamp - now)


def color_time_since(timestamp, utc=True):
    now = datetime.now()
    if utc:
        now = now.astimezone()

    delta = timestamp - now
    if abs(delta) < timedelta(0, 60 * 60):
        colorfunc = red
    elif abs(delta) < timedelta(1, 0):
        colorfunc = yellow
    elif abs(delta) < timedelta(7):
        colorfunc = green
    else:
        colorfunc = noop

    return colorfunc(format_timedelta(delta))


# we're using base 2 units (e.g. kibibyte, mebibyte)
def format_bytes(num):
    """Integer "bytes" formatting with SI suffixes."""
    # uses side-effects of iterating through a collection to select the
    # correct suffix
    for suffix in [""] + SI_SUFFIXES:
        if num > 1024:
            num /= 1024
        else:
            break

    return "{:.2f}{:}".format(num, suffix)  # pylint: disable=undefined-loop-variable


def parse_bytes(num):
    """Attempt to reverse integer "bytes" formatting."""
    factor = 1
    suffix = num[-1].upper()
    # may have '100B' or '24KB', etc
    if suffix == "B":
        num = num[:-1]
        suffix = num[-1].upper()
    if suffix in SI_SUFFIXES:
        factor = 2 ** (10 * (SI_SUFFIXES.index(suffix) + 1))
        # eg, 'K' -> 2 ** (10 * 1); G -> 2 ** (10 * 3)
    # if this throws an exception, let it propagate
    return float(num[:-1]) * factor


def get_creds(env_prefix=None):
    """
    Get user credentials.

    if `env_prefix` is provided, look for environment variables matching
    "%s_USER" and "%s_PASSWORD". if `env_prefix` is not provided, or if
    matching environment variables do not exist, interactively request
    credentials from the user."""
    user, pw = None, None
    if env_prefix:
        user_var = "%s_USER" % env_prefix
        pw_var = "%s_PASSWORD" % env_prefix
        if user_var in os.environ and pw_var in os.environ:
            user = os.environ[user_var]
            pw = os.environ[pw_var]
        else:
            warnings.warn("Credential environment variables not found: %s, %s" % (user_var, pw_var))

    if not (user and pw):
        user_guess = getpass.getuser()
        user = input("Username [%s]: " % user_guess) or user_guess
        pw = getpass.getpass()
        if not pw:
            raise ValueError("No password supplied")

    return (user, pw)


def columnize(alist, yfirst=True, width=None):
    width = width or get_terminal_size().columns - 2
    alist = list(map(str, alist))

    # process is: divide list into two columns. check to see if columns will
    # fit to screen. if yes, increase number of columns & try again. if no,
    # reduce number of columns (minimum 1 b/c we start with 2) and print to
    # screen

    def get_columns(alist, numcol):
        if yfirst:
            height = math.ceil(len(alist) / numcol)
            columns = [alist[(i * height) : ((i + 1) * height)] for i in range(numcol)]
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
    for line in zip_longest(*columns, fillvalue=""):
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
    width = kwargs.pop("width", get_terminal_size().columns)
    pprint(*args, width=width, **kwargs)


def group_by(collection, keyfunc):
    grouped = {}
    for item in collection:
        grouped.setdefault(keyfunc(item), []).append(item)
    return grouped


def compose(*functions):
    """
    Compose a sequence of functions into a single function.
    E.g. compose(f, g, h)(x) == f(g(h(x)))
    """
    return reduce((lambda f, g: lambda *args, **kwargs: f(g(*args, **kwargs))), functions)


def depthwalk(top, depth=0, **kwargs):
    """just like `os.walk`, but with new added `depth` parameter!"""
    depthmap = {top: 0}
    for path, dirs, files in os.walk(top, **kwargs):
        yield path, dirs, files
        here = depthmap[path]
        if here >= depth:
            dirs.clear()
            continue
        for dir in dirs:
            child = os.path.join(path, dir)
            depthmap[child] = here + 1


def format_seconds(seconds):
    if not isinstance(seconds, (int, float, Decimal)):
        raise TypeError("seconds must be a number", seconds)

    absval = abs(seconds)
    cutoff = 1 / 3

    if absval == 0 or absval > cutoff:
        return str(timedelta(seconds=float(seconds)))

    suffixes = ["ms", "μs", "ns", "ps"]

    sign = int(seconds > 0) or -1
    del seconds

    for suffix in suffixes:
        absval *= 1000
        if absval > cutoff:
            break

    return f"{absval * sign:.3g}{suffix}"


def just_timeit(stmt, **kwargs):
    """
    just_timeit(stmt, setup)

    wrapper around timeit.Timer that has all the convenience of the cmdline interface
    """
    if not kwargs:
        # attempt to get caller's globals
        frame = inspect.currentframe()
        frame = frame.f_back if frame else None
        kwargs["globals"] = frame.f_globals if frame else None
    timer = timeit.Timer(stmt, **kwargs)
    try:
        # pick a count where duration > 0.2 sec
        count, duration = timer.autorange()
        results = [duration]
        # take 19 samples (for 20 total) of `count` loops
        results += timer.repeat(19, count)
    except Exception:
        timer.print_exc()
        return

    # take aggregates
    min_r, avg_r, max_r = min(results), sum(results) / len(results), max(results)

    summary = f"""
        iterations: {count}
        min: {min_r:.3f} ({format_seconds(min_r / count)})
        avg: {avg_r:.3f} ({format_seconds(avg_r / count)})
        max: {max_r:.3f} ({format_seconds(max_r / count)})
        """
    print(dedent(summary).strip())


def jql(data, expr=".") -> None:
    if not isinstance(data, str):
        data = json.dumps(data)

    subprocess.run(f"jq -C {shlex.quote(expr)} | less", input=data.encode("utf-8"), shell=True)


def dig(something, *keys, default=None):
    """
    Dig through a nested datastructure.

    ```python
    value = dig(something, "one", 2, "three", default=...)
    # is roughly equivalent to
    try:
        value = something["one"][2]["three"]
    except (TypeError, IndexError, KeyError):
        value = default
    ```
    """
    current = something
    try:
        for key in keys:
            current = current[key]
        return current
    except (TypeError, IndexError, KeyError):
        return default


class LoggingContext:
    """
    A Context Manager for logging configuration.

    # https://docs.python.org/3/howto/logging-cookbook.html
    """

    def __init__(self, logger, level=None, handler=None, close=True):
        self.logger = logger
        self.level = level
        self.handler = handler
        self.close = close

    def __enter__(self):
        if self.level is not None:
            self.old_level = self.logger.level
            self.logger.setLevel(self.level)
        if self.handler:
            self.logger.addHandler(self.handler)

    def __exit__(self, et, ev, tb):
        if self.level is not None:
            self.logger.setLevel(self.old_level)
        if self.handler:
            self.logger.removeHandler(self.handler)
        if self.handler and self.close:
            self.handler.close()
