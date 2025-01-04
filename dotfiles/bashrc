#!/usr/bin/env bash
# bash init script

_bash_init() {
    # set +o history
    declare -g _BASH_INIT_STARTED=1

    shopt -s checkhash
    shopt -s cdspell
    shopt -s dirspell
    shopt -s no_empty_cmd_completion

    # set -eu -o functrace errtrace
    # # shopt -s extdebug
    # _BASHLIB_LOGLEVEL=debug
    # _BASHLIB_FLAGS=:replace_exec:stacktrace:

    local item
    for item in ~/.bash_init/*; do
        if [[ $item == *.sh ]]; then
            source "$item"
        else
            echo >&2 "[!] $FUNCNAME: Will not source file: $item"
        fi
        # set +vx
    done

    # set -o history
    # set +eu
} && export -f _bash_init

# set -vx

# don't run twice, and don't recurse
[[ ${_BASH_INIT_RUN-} ]] || _bash_init

# set +vx

# and don't let anybody add any extra crap!
return 0
