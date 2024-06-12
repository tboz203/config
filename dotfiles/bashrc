#!/usr/bin/env bash
# bash init script
# vim: tw=119
# shellcheck disable=2015

# : "${_BASH_INIT_DEBUG:=pause:verbose:nodebug:notrace:source}"
# set -vx

shopt -s checkhash
shopt -s execfail
shopt -s expand_aliases

shopt -s extglob
shopt -s globstar
shopt -s nullglob

# I wanna set this, but it seems like it would probably break things...
# shopt -s nocaseglob
# this one *definitely* caused some problems :/
# shopt -s failglob

if [[ ${BASH_VERSINFO[0]} -ge 5 ]]; then
    shopt -s globskipdots
fi

inlist()
{
    # test whether a path-like list contains an element
    # usage: inlist ELEMENT LIST
    [[ :$2: == *:"$1":* ]]
}

# set -o pipefail

# echo a message when debugging
alias _verbose='! inlist verbose "${_BASH_INIT_DEBUG-}" || echo >&2'
alias _debug='! inlist debug "${_BASH_INIT_DEBUG-}" || echo >&2 "[.] ${FUNCNAME[0]}:"'
# check for an executable in the path
alias haveexe='type -P > /dev/null'
# check for any callable
alias havecmd='type -t > /dev/null'

# By default, every invocation should run this script
[[ -v BASH_ENV ]] || export BASH_ENV="$HOME/.bashrc"

# shellcheck disable=2120
bash_init()
{
    declare -g _BASH_INIT_STARTED=1
    [[ $# -gt 0 ]] && unset _BASH_INIT_DONE

    _verbose top of bash init

    local item
    for item in ~/.bash_init.d/*; do
        if [[ $item =~ .*\.(sh|bash)$ ]]; then
            _verbose "# sourcing init script $item"
            inlist verbose "${_BASH_INIT_DEBUG-}" && echo "PATH: ${PATH//:/$'\n      '}" || true

            . "$item"
            havecmd _debug_reset && _debug_reset || true
        else
            echo >&2 "[!] will not source file: $item"
        fi
    done

    _verbose bottom of bash init

    declare -g _BASH_INIT_DONE=1
}

# don't run twice, and don't recurse
[[ -v _BASH_INIT_STARTED ]] || bash_init
