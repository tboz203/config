#!/usr/bin/env python

from __future__ import print_function

from subprocess import Popen, CalledProcessError, PIPE

__all__ = ['call', 'CallError']


class CallError(CalledProcessError):
    '''Error from call. Additionally, stores stdout and stderr'''
    def __init__(self, retcode, cmd, stdout, stderr):
        super(CallError, self).__init__(retcode, cmd, stdout)
        self.stdout = stdout
        self.stderr = stderr

def call(*popenargs, raise_on_error=True, **kwargs):
    '''Call an external command. if `raise_on_error`, return stdout and stderr as a 2-tuple.
    or a CallError if the return code is not 0. if not `raise_on_error`, return
    a 3-tuple of return code, stdout, and stderr'''

    kwargs['stdout'] = PIPE
    kwargs['stderr'] = PIPE
    p = Popen(*popenargs, **kwargs)
    stdout, stderr = p.communicate()
    stdout = trydecode(stdout)
    stderr = trydecode(stderr)
    retcode = p.wait()
    if raise_on_error:
        if retcode != 0:
            raise CallError(retcode, p.args, stdout, stderr)
        else:
            return (stdout, stderr)
    else:
        return (retcode, stdout, stderr)

def trydecode(data, encoding='utf-8'):
    try:
        return data.decode(encoding)
    except UnicodeEncodeError:
        return data
