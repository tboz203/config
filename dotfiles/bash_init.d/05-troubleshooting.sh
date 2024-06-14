# bash environment troubleshooting

# https://flokoe.github.io/bash-hackers-wiki/scripting/debuggingtips/#making-xtrace-more-useful
export PS4='+[$EPOCHREALTIME] ($BASH_SOURCE:$LINENO): ${FUNCNAME:+$FUNCNAME(): }'

_debug_var()
{
    # print variable state
    (($# >= 1)) || return 2
    [[ -o xtrace ]] || inlist trace "${_BASH_INIT_DEBUG-}" || inlist debug "${_BASH_INIT_DEBUG-}" || return 0
    printf >&2 "%s\n" "[.] ${FUNCNAME[0]} (${FUNCNAME[1]}) $*"
    local line
    declare -p -- "$@" 2>&1 | while read -r line; do
        printf '  %s\n' "$line"
    done
}

_debug_trace()
{
    # start tracing bash execution
    _debug_reset
    if inlist trace "${_BASH_INIT_DEBUG-}"; then
        declare -g _BASH_INIT_DEBUG_RESET_FLAGS
        read -r -d '' _BASH_INIT_DEBUG_RESET_FLAGS <<< "$(shopt -op verbose xtrace)"
        set -vx
    fi
}

_debug_reset()
{
    # stop tracing bash execution
    if [[ -v _BASH_INIT_DEBUG_RESET_FLAGS ]]; then
        eval "$_BASH_INIT_DEBUG_RESET_FLAGS"
        unset _BASH_INIT_DEBUG_RESET_FLAGS
    fi
}

# The need for this is largely obsoleted by the PS4 set above
# source_verbose()
# {
#     # print names of sourced files when entering and exiting
#     inlist source "${_BASH_INIT_DEBUG-}" && printf "# sourcing %s\n" "$*" || true
#     local retval=0
#     builtin source "$@" || retval=$?
#     inlist source "${_BASH_INIT_DEBUG-}" && printf "# leaving %s (return $retval)\n" "$*" || true
#     return $retval
# }
#
# alias source=source_verbose
# alias .=source_verbose

replace_exec()
{

    inlist pause "${_BASH_INIT_DEBUG-}" || return 0
    # shellcheck disable=2317
    exec()
    {
        printf >&2 "will run: %s\n" "$*"
        read -rp "continue? "
        local retval=0
        "$@" || retval=$?
        printf >&2 "exited with $retval (%s)" "$*"
        read -rp "continue? "
        exit "$retval"
    }
}

print_stack()
{
    local i=0
    # printf "%s %s %s\n" "$LINENO" "${FUNCNAME[0]}" "${BASH_SOURCE[0]}"
    while caller $i; do ((i++)); done
}

stack()
{
    local line func file
    print_stack | while read -r line func file; do
        printf "%s\n" "$func ($file:$line)"
    done
}

called-at()
{
    [[ $# -le 1 && ${1-} != -* ]] || return 2
    local idx=${1:-0}
    ((idx >= 0 && idx < ${#BASH_SOURCE[@]})) || return 1
    echo "${FUNCNAME[$idx + 1]} (${BASH_SOURCE[$idx + 1]}:${BASH_LINENO[$idx]})"
}

stackline()
{
    local -a stack
    for ((i = 1; i < ${#BASH_SOURCE[@]}; i++)); do
        stack+=("${FUNCNAME[$i]} (${BASH_SOURCE[$i]}:${BASH_LINENO[$i - 1]})")
    done

    [[ -v stack ]] || return 0

    while
        printf "%s" "${stack[-1]}"
        unset "stack[-1]"
        [[ -v stack ]]
    do
        printf " > "
    done

    printf "\n"
}

inlist stacktrace "${_BASH_INIT_DEBUG-}" && trap 'print_stack' EXIT || true
