# bashlib.sh
# load bashlib

function _bashlib {
    # step one: where are we?
    if [[ $- == *i* ]]; then declare -g _SHELL_INTERACTIVE=1; fi
    if shopt -qp login_shell; then declare -g _SHELL_LOGIN=1; fi

    # step two: complain
    if [[ ${BASH_VERSINFO[0]} -lt 5 && ${_SHELL_INTERACTIVE-} ]]; then
        echo >&2 "Hi! Go update your bash please ($BASH_VERSION)"
    fi

    # step three: blather
    [[ ${_BASHLIB_LOGLEVEL-} ]] || declare -g _BASHLIB_LOGLEVEL=normal
    [[ ${_BASHLIB_FLAGS-} ]] || declare -g _BASHLIB_FLAGS=:noreplace_exec:
    [[ ${_BASHLIB_ROOT-} ]] || declare -g _BASHLIB_ROOT=~/.bashlib

    # step four: complain again
    if [[ ! -d ${_BASHLIB_ROOT:?} ]]; then
        echo >&2 "_BASHLIB_ROOT ($_BASHLIB_ROOT) does not exist"
        return 1
    fi

    # step five: prepare
    shopt -s expand_aliases
    shopt -s extglob
    shopt -s globstar
    shopt -s nullglob
    shopt -u nocasematch

    # step six: get to work
    local item
    for item in "$_BASHLIB_ROOT"/*; do
        if [[ $item == *.sh ]]; then
            source "$item"
        else
            echo >&2 "[!] $FUNCNAME: Will not source file: $item"
        fi
    done
}

_bashlib
