#!/usr/bin/env bash
# bash init script

_bash_init() {
    shopt -s checkhash
    shopt -s cdspell
    shopt -s dirspell
    shopt -s no_empty_cmd_completion

    # shopt -s extdebug

    # set -eu -o functrace errtrace
    # _BASHLIB_LOGLEVEL=debug
    # _BASHLIB_FLAGS=:replace_exec:stacktrace:

    local item
    for item in ~/.bash_init/*; do
        if [[ $item == *.sh ]]; then
            source "$item"
        else
            echo >&2 "[!] $FUNCNAME: Will not source file: $item"
        fi
    done

} && export -f _bash_init

_bash_init

# ignore any crap installer scripts try to append to this file
return 0
