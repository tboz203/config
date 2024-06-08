# bash environment troubleshooting
# disabling warnings for `A && B || C`, declare & assign separately, and unreachable commands
# shellcheck disable=2015,2155,2317

# https://flokoe.github.io/bash-hackers-wiki/scripting/debuggingtips/#making-xtrace-more-useful
export PS4='+($BASH_SOURCE:$LINENO): ${FUNCNAME:+$FUNCNAME(): }'

_debug_var()
{
    # print variable state
    [[ $# -gt 0 ]] || return 1
    inlist debug "${_BASH_INIT_DEBUG-}" || return 0
    _debug "(${FUNCNAME[1]}) $*"
    local declarations=$(declare -p -- "$@" 2>&1 || true)
    echo >&2 "    ${declarations//$'\n'/&    }"
}

_debug_trace()
{
    # start tracing bash execution
    _debug_reset
    if inlist trace "${_BASH_INIT_DEBUG-}"; then
        [[ -o verbose ]] || _BASH_INIT_DEBUG_RESET_FLAGS+=v
        [[ -o xtrace ]] || _BASH_INIT_DEBUG_RESET_FLAGS+=x
        set -vx
    fi
}

_debug_reset()
{
    # stop tracing bash execution
    if [[ -v _BASH_INIT_DEBUG_RESET_FLAGS ]]; then
        set "+$_BASH_INIT_DEBUG_RESET_FLAGS"
        unset _BASH_INIT_DEBUG_RESET_FLAGS
    fi
}

source_verbose()
{
    # print names of sourced files when entering and exiting
    inlist source "${_BASH_INIT_DEBUG-}" && echo "# sourcing $*" || true
    local retval=0
    builtin source "$@" || retval=$?
    inlist source "${_BASH_INIT_DEBUG-}" && echo "# leaving $* (return $retval)" || true
    return $retval
}

alias source=source_verbose
alias .=source_verbose

replace_exec()
{

    inlist pause "${_BASH_INIT_DEBUG-}" || return 0
    exec()
    {
        echo >&2 "will run: $*"
        read -rp "continue? "
        local retval=0
        "$@" || retval=$?
        echo >&2 "exited with $retval ($*)"
        read -rp "continue? "
        exit "$retval"
    }
}

print_stack()
{
    local i=0
    # echo "$LINENO $FUNCNAME $BASH_SOURCE"
    while caller $i; do ((i++)); done
}

stackline()
{
    inlist debug "${_BASH_INIT_DEBUG-}" || return 0
    local stack="$(print_stack)"
    stack=${stack#*$'\n'}
    echo "${stack//$'\n'/ < }"
}

inlist stacktrace "${_BASH_INIT_DEBUG-}" && trap 'print_stack' EXIT || true
