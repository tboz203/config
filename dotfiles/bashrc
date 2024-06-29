#!/usr/bin/env bash
# bash init script

_bash_init() {
    declare -g _BASH_INIT_STARTED=1

    shopt -s checkhash

    local item
    for item in ~/.bash_init/*; do
        if [[ $item == *.sh ]]; then
            source "$item"
        else
            echo >&2 "[!] $FUNCNAME: Will not source file: $item"
        fi
        set +vx
    done
} && export -f _bash_init

# don't run twice, and don't recurse
[[ ${_BASH_INIT_RUN-} ]] || _bash_init
