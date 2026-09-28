import inspect
import logging
import logging.config

def _get_conf_dict(name):
    # using a func so we can modify it elsewhere without affecting all
    # loggers
    return {
        'version': 1,
        'formatters': {
            'verbose': {
                'format': ('[%(levelname)8s %(asctime)s] %(message)s'),
            },
        },
        'handlers': {
            'file': {
                'level': 'DEBUG',
                'formatter': 'verbose',
                'class': 'logging.FileHandler',
                'filename': '%s.debug.log' % name,
            },
            'console': {
                'level': 'INFO',
                'formatter': 'verbose',
                'class': 'logging.StreamHandler',
            },
        },
        'loggers': {
            name: {
                'level': 'DEBUG',
                'handlers': ['file', 'console'],
            },
        },
    }


def get_module_name(depth=1):
    '''get the module name of the calling function. if the optional parameter
    `depth` is specified, traverse that many layers up the stack before
    determining the module name.'''

    frame = inspect.currentframe()
    one_up = inspect.getouterframes(frame)[depth]
    filename = one_up[1]
    modulename = inspect.getmodulename(filename)

    del frame, one_up

    return modulename


def get_logger(name=None, conf_dict=None):
    '''get a logger, with some standard configuration. If a name is passed, use
    that for the logger. otherwise, detect the name of the calling module, and
    use that.'''

    if name is None:
        name = get_module_name(2)

    if conf_dict is None:
        conf_dict = _get_conf_dict(name)

    logging.config.dictConfig(conf_dict)

    return logging.getLogger(name)

