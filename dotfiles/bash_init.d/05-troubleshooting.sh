# bash environment troubleshooting

_start_debug_trace()
{
    _stop_debug_trace
    if [[ -v _BASH_INIT_DEBUG ]]; then
        _BASH_INIT_TRACE_SOURCE=1
        [[ $- == *v* ]] || _BASH_INIT_DEBUG_FLAGS+=v
        [[ $- == *x* ]] || _BASH_INIT_DEBUG_FLAGS+=x
        set "-$_BASH_INIT_DEBUG_FLAGS"
    fi
}

_stop_debug_trace()
{
    unset _BASH_INIT_TRACE_SOURCE
    if [[ -v _BASH_INIT_DEBUG_FLAGS ]]; then
        set "+$_BASH_INIT_DEBUG_FLAGS"
        unset _BASH_INIT_DEBUG_FLAGS
    fi
}

[[ -v _BASH_INIT_DEBUG ]] || return

trap 'havecmd stacktrace && stacktrace' EXIT

alias .=source

source()
{
    [[ -v _BASH_INIT_TRACE_SOURCE ]] && echo "# sourcing $*"
    local retval=0
    builtin source "$@" || retval=$?
    [[ -v _BASH_INIT_TRACE_SOURCE ]] && echo "# leaving $* (return $retval)"
    return $retval
}
