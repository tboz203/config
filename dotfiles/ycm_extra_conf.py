#!/usr/bin/env python

import logging
import logging.config
import subprocess
from pathlib import Path
from pprint import pformat

LOGGING_CONFIG = {
    "version": 1,
    "disable_existing_loggers": False,
    "formatters": {
        "verbose": {
            "format": ("[%(levelname)8s %(asctime)s %(name)s] %(message)s"),
            # "datefmt": "%Y-%m-%d %H:%M:%S",
        },
    },
    "handlers": {
        "logfile": {
            "level": "DEBUG",
            "formatter": "verbose",
            "class": "logging.FileHandler",
            "filename": Path("~/ycm_extra_conf.log").expanduser().as_posix(),
        },
    },
    "loggers": {
        "ycm.extra_conf": {
            "handlers": ["logfile"],
            "level": "DEBUG",
            "propagate": False,
        },
    },
}

# logging.config.dictConfig(LOGGING_CONFIG)
logger = logging.getLogger("ycm.extra_conf")


class LazyPFormat:
    """quick class to lazily wrap pformat"""

    def __init__(self, *args, **kwargs):
        self.args = args
        self.kwargs = kwargs

    def __str__(self):
        return pformat(*self.args, **self.kwargs)


def get_python_interpreter_path(kwargs):
    # first check for vim setting
    client_data = kwargs.get("client_data", {})
    vim_interpreter_path = client_data.get("g:ycm_python_interpreter_path")
    if vim_interpreter_path:
        return vim_interpreter_path

    # if we find a venv between here and root, use that
    location = Path(kwargs.get("filename", ".")).absolute()
    logger.info("location: %s", location)
    for parent in location.parents:
        for suffix in ["venv/bin/python", ".venv/bin/python"]:
            venv_py = parent.joinpath(suffix)
            logger.debug("trying venv = %s", venv_py)
            if venv_py.exists():
                logger.info("bingo venv = %s", venv_py)
                return str(venv_py)

    # if we didn't find anything that way, fall back to pyenv
    logger.info("no joy, setting via pyenv")
    return subprocess.getoutput("pyenv which python3")


def get_python_sys_path(kwargs):
    # all we've got here is vim setting check
    client_data = kwargs.get("client_data", {})
    vim_sys_path = client_data.get("g:ycm_python_sys_path", [])
    return vim_sys_path


def Settings(**kwargs):
    # this is the actual entrypoint
    conf = {
        # "java_binary_path": "/usr/lib/jvm/java-11/bin/java",
        "java_binary_path": "/usr/lib/jvm/java-17-amazon-corretto.x86_64/bin/java",
    }
    try:
        logger.info("kwargs:\n%s", LazyPFormat(kwargs))
        if kwargs.get("language") == "python":
            conf["interpreter_path"] = get_python_interpreter_path(kwargs)
            conf["sys_path"] = get_python_sys_path(kwargs)
        logger.info("final conf:\n%s", LazyPFormat(conf))
    except Exception as exc:
        try:
            logger.error("trapped an exception during extra_conf: %s", exc)
        except Exception:
            pass
    return conf
