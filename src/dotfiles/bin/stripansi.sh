#!/usr/bin/env bash

declare -a POSITIONAL
while (($#)); do
    arg=$1 && shift
    case $arg in
        -*) HELP=1 ;;
        *) POSITIONAL+=("$arg") ;;
    esac
done

set -- "${POSITIONAL[@]}"

if [[ ${HELP-} ]]; then
    echo >&2 "$BASH_SOURCE: strip ANSI escape color sequences from named files, or stdin"
    echo >&2 "Usage: $BASH_SOURCE [FILE...]"
    return 1
fi

PATTERNS=(
    # color and graphics directives
    -e 's/\x1b\[[0-9]*(;[0-9]*)*m//g'

    # cursor movement
    -e 's/\x1b\[[0-9]*[A-G]//g'
    -e 's/\x1b\[[0-9]+;[0-9]+H//g'

    # erase
    -e 's/\x1b\[[0-9]*[JK]//g'

    # and carriage return...
    -e 's/\x0d//g'
)

exec sed -r "${PATTERNS[@]}" "$@"
