#!/usr/local/bin/python3
"""Find python modules"""

import argparse
from importlib.util import find_spec


def findmodule(name):
    """given module name as a string, find the location it would be loaded from"""
    return getattr(find_spec(name), "origin", None)


def summarize_locations(modules):
    """given a list of module names as strings, print a summary of their locations"""
    width = max(map(len, modules))
    for module in modules:
        location = findmodule(module)
        if location is None:
            location = "(module not found)"
        print("{:<{width}} -> {}".format(module, location, width=width))


def main():
    """When this module is run as a script, accept a list of module names on
    the command line, and print a summary of their locations."""
    parser = argparse.ArgumentParser(description="Find named python modules")
    parser.add_argument("modules", nargs="+", help="the names of modules to be searched for")
    parser.add_argument("-c", "--clean", action="store_true", help="don't summarize; print only the machine location")
    args = parser.parse_args()
    if args.clean:
        for module in args.modules:
            print(findmodule(module) or "")
    else:
        summarize_locations(args.modules)


if __name__ == "__main__":
    main()
