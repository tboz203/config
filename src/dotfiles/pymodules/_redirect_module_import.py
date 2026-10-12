"""
Mechanism for lazily redirecting module imports
"""

import importlib
import logging
import sys
from types import ModuleType
from typing import Any, Union


class RedirectedModule(ModuleType):
    """
    A module that lazily redirects all interactions to a different module.
    """

    def __init__(self, requested_name: str, real_name: str, warning: Union[str, bool] = True) -> None:
        super().__init__(requested_name)

        if isinstance(warning, str):
            warning_text = warning
        elif warning:
            warning_text = f"Module '{requested_name}' has been deprecated; please use '{real_name}'"
        else:
            warning_text = None

        super().__setattr__("_real_name", real_name)  # type: str
        super().__setattr__("_real_module", None)  # type: Optional[ModuleType]
        super().__setattr__("_warning", warning_text)  # type: Optional[str]

    def _resolve(self) -> ModuleType:
        lookup = super().__getattribute__("_real_module")
        if lookup is not None:
            return lookup

        name = super().__getattribute__("__name__")
        real_name = super().__getattribute__("_real_name")
        real_module = importlib.import_module(real_name)
        super().__setattr__("_real_module", real_module)

        warning = super().__getattribute__("_warning")
        if warning:
            logger = logging.getLogger(name)
            logger.warning(warning)

        return real_module

    def __setattr__(self, name: str, value: Any, /) -> None:
        real_module = super().__getattribute__("_resolve")()
        return setattr(real_module, name, value)

    def __getattribute__(self, name: str, /) -> Any:
        real_module = super().__getattribute__("_resolve")()
        return getattr(real_module, name)

    def __delattr__(self, name: str, /) -> None:
        real_module = super().__getattribute__("_resolve")()
        return delattr(real_module, name)


def redirect_module_import(requested_name: str, real_name: str) -> None:
    sys.modules[requested_name] = RedirectedModule(requested_name, real_name)
