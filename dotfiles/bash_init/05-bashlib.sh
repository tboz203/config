# bashlib.sh

_bashlib()
{
    # number one: complain
    if [[ ${BASH_VERSINFO[0]} -lt 5 ]]; then
        echo >&2 "Hi! go update your bash please..."
    fi

    [[ ${_BASHLIB_LOGLEVEL-} ]] || declare -g _BASHLIB_LOGLEVEL=
    [[ ${_BASHLIB_FLAGS-} ]] || declare -g _BASHLIB_FLAGS=:noreplace_exec:
    [[ ${_BASHLIB_ROOT-} ]] || declare -g _BASHLIB_ROOT=~/.bashlib

    shopt -s expand_aliases

    shopt -s extglob
    shopt -s globstar
    shopt -s nullglob

    shopt -s extdebug

    # shopt -s nocaseglob
    # shopt -s failglob

    # set -o pipefail

    if [[ ${BASH_VERSINFO[0]} -ge 5 ]]; then
        shopt -s globskipdots
    fi

    local item
    for item in "${_BASHLIB_ROOT?}"/*; do
        source "$item"
    done
}

_bashlib
