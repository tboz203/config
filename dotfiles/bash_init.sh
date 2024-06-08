#!/usr/bin/env bash
# bash init script
# vim: tw=119
# shellcheck disable=2015

declare -g _BASH_INIT_DEBUG
: "${_BASH_INIT_DEBUG:=pause:verbose:nodebug:trace:source}"

shopt -s checkhash
shopt -s execfail
shopt -s expand_aliases

shopt -s extglob
# shopt -s nullglob
shopt -s failglob
shopt -s globstar
shopt -s globskipdots

# I wanna set this, but it seems like it would probably break things...
# shopt -s nocaseglob

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

maybe()
{
    # run a command if it exists
    [[ $# -gt 0 ]] || return 1
    if havecmd "$1"; then
        "$@" || local retval=$?
    fi
    return "${retval:-0}"
}

pathmunge()
{
    # minimal path builder
    [[ :$PATH: != *:"$1":* && -d "$1" ]] || PATH="$1:$PATH"
}

pathmunge /usr/local/sbin
pathmunge /usr/local/bin
pathmunge "$HOME/.local/bin"
pathmunge "$HOME/.bin"
pathmunge "$HOME/bin"

# export MAILTO=thomas.bozeman@cgifederal.com
# export LC_ALL=en_US.UTF-8
# export LANG=en_US.UTF-8
# export EDITOR=nvim
# export PAGER=less

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
            . "$item"
            maybe _debug_reset
        else
            echo >&2 "[!] will not source file: $item"
        fi
    done

    _verbose bottom of bash init

    declare -g _BASH_INIT_DONE=1
}

# don't run twice, and don't recurse
[[ -v _BASH_INIT_STARTED ]] || bash_init
