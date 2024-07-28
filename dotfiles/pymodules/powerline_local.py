#!/usr/bin/env python

from powerline.segments import Segment, with_docstring
from powerline.theme import requires_segment_info


@requires_segment_info
def environment(pl, segment_info, variable=None, ignore=None):
    """Return the value of an environment variable, if defined

    :param string variable:
            The name of an environment variable
    :param Container ignore:
            An optional collection of values to ignore
    """
    value = segment_info["environ"].get(variable)
    if ignore and value in ignore:
        return None
    return value
