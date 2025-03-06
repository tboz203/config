#!/usr/bin/env python


def install_interactivehook():
    import sys

    # using the NoneType constructor as a noop function
    noop = type(None)
    old_interactivehook = getattr(sys, "__interactivehook__", noop)

    def tbozeman_interactivehook():
        import shutil
        import traceback
        from pprint import pformat

        def get_columns():
            if hasattr(shutil, "get_terminal_size"):
                return shutil.get_terminal_size().columns
            return 80

        def new_displayhook(value):
            if value is None:
                return
            __builtins__._ = None
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
            __builtins__._ = value

        def new_excepthook(exc_type, exc_value, exc_traceback):
            __builtins__._ = None
            text = str.join(
                "", traceback.format_exception(exc_type, exc_value, exc_traceback)
            )
            try:
                sys.stderr.write(text)
            except UnicodeEncodeError:
                bytes_ = text.encode(sys.stderr.encoding, "backslashreplace")
                if hasattr(sys.stderr, "buffer"):
                    text = bytes_.decode(sys.stderr.encoding, "strict")
                    sys.stderr.write(text)
            __builtins__._ = exc_value

        sys.displayhook = new_displayhook
        sys.excepthook = new_excepthook
        old_interactivehook()

    setattr(sys, "__interactivehook__", tbozeman_interactivehook)


install_interactivehook()
del install_interactivehook
