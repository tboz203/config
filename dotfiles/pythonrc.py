#!/usr/bin/env python


def install():
    import shutil
    import sys
    import traceback
    from pprint import pformat

    try:
        import builtins
    except ImportError:
        builtins = __builtins__

    def get_columns():
        if hasattr(shutil, "get_terminal_size"):
            return shutil.get_terminal_size().columns
        return 80

    def new_displayhook(value):
        if value is None:
            return
        builtins._ = None
        text = pformat(value, width=get_columns())
        try:
            sys.stdout.write(text)
        except UnicodeEncodeError:
            bytes_ = text.encode(sys.stdout.encoding, "backslashreplace")
            if hasattr(sys.stdout, "buffer"):
                sys.stdout.buffer.write(bytes_)
            else:
                text = bytes_.decode(sys.stdout.encoding, "strict")
                sys.stdout.write(text)
        sys.stdout.write("\n")
        builtins._ = value

    def new_excepthook(exc_type, exc_value, exc_traceback):
        builtins._ = None
        text = "".join(traceback.format_exception(exc_type, exc_value, exc_traceback))
        try:
            sys.stderr.write(text)
        except UnicodeEncodeError:
            bytes_ = text.encode(sys.stderr.encoding, "backslashreplace")
            if hasattr(sys.stderr, "buffer"):
                text = bytes_.decode(sys.stderr.encoding, "strict")
                sys.stderr.write(text)
        builtins._ = exc_value

    sys.displayhook = new_displayhook
    sys.excepthook = new_excepthook


install()
del install
