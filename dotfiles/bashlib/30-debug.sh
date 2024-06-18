# bash environment troubleshooting

# https://flokoe.github.io/bash-hackers-wiki/scripting/debuggingtips/#making-xtrace-more-useful
export PS4='+\[\e[2m\][$EPOCHREALTIME] (${BASH_SOURCE-(main)}:$LINENO): ${FUNCNAME:+$FUNCNAME(): }\[\e[22m\]'

alias _verbose='#'
alias _debug='#'
case :${_BASHLIB_LOGLEVEL-}: in
    *:trace:*) ;&
    *:debug:*) alias _debug=' ' ;&
    *:verbose:*) alias _verbose=' ' ;&
    *) ;;
esac

inspect_var()
{
    (($# >= 1)) || return 2
    declare -p -- "$@" 2>&1 | indent >&2
}

_trace_set()
{
    # start tracing bash execution
    _trace_reset
    if [[ ${_BASHLIB_LOGLEVEL-} == trace ]]; then
        # shellcheck disable=2155
        declare -g _BASHLIB_TRACE_FLAGS="$(shopt -op verbose xtrace)"
        set -vx
    fi
}

_trace_reset()
{
    # stop tracing bash execution
    if [[ -v _BASHLIB_TRACE_FLAGS ]]; then
        eval "$_BASHLIB_TRACE_FLAGS"
        unset _BASHLIB_TRACE_FLAGS
    fi
}

# The need for this is largely obsoleted by the PS4 set above
# source_verbose()
# {
#     # print names of sourced files when entering and exiting
#     inlist source "${_BASHLIB_FLAGS-}" && printf "# sourcing %s\n" "$*" || true
#     local retval=0
#     builtin source "$@" || retval=$?
#     inlist source "${_BASHLIB_FLAGS-}" && printf "# leaving %s (return $retval)\n" "$*" || true
#     return $retval
# }
#
# alias source=source_verbose
# alias .=source_verbose

replace_exec()
{

    inlist replace_exec "${_BASHLIB_FLAGS-}" || return 0
    # shellcheck disable=2317
    exec()
    {
        _verbose stackline
        _log "will run: $*"
        read -rp "[press enter to continue] "
        local retval=0
        "$@" || retval=$?
        _log "exited with $retval ($*)"
        read -rp "[press enter to continue] "
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
    (($# <= 1)) || return 2
    local idx=${1:-0}
    ((idx >= 0 && idx < ${#BASH_SOURCE[@]})) || return 1
    printf "%s (%s:%s)\n" "${FUNCNAME[$idx + 1]}" "${BASH_SOURCE[$idx + 1]}" "${BASH_LINENO[$idx]}"
}

stackline()
{
    local -a stack=()
    for ((i = ${#BASH_SOURCE[@]} - 1; i > 1; i--)); do
        stack+=("${FUNCNAME[$i]} (${BASH_SOURCE[$i]}:${BASH_LINENO[$i - 1]})")
    done

    ((${#stack[@]} >= 1)) || return 0

    printf "%s" "${stack[0]}"

    local frame
    for frame in "${stack[@]:1}"; do
        printf " > %s" "$frame"
    done

    echo
}

showframe()
{
    (($# == 3)) || return 2
    local filename=$1
    local funcname=$2
    local lineno=$3

    # read into array $lines from $filename at $lineno
    # (such that $index = $lineno) with $context surrounding lines
    local -a lines=()
    file_context

    echo "    $filename:$lineno (in $funcname):"

    if ((${#lines[@]} == 0)); then
        echo "   >> (nil)"
    else
        local ctx_lineno prefix
        for ctx_lineno in "${!lines[@]}"; do
            ((ctx_lineno == lineno)) && prefix="   >>" || prefix="     "
            echo "$prefix $ctx_lineno ${lines[$ctx_lineno]}"
        done
    fi
}

stacktrace()
{
    # print the current call stack
    local context=2 top=0 bottom=0

    local opt OPTARG OPTIND HELP=
    while getopts :hc:t:b: opt; do
        case $opt in
            h) HELP=0 ;;
            c) context=$OPTARG ;;
            t) top=$OPTARG ;;
            b) bottom=$OPTARG ;;
            :)
                echo >&2 "[X] ${FUNCNAME[0]}: required argument not found: $OPTARG"
                HELP=2
                ;;
            ?)
                echo >&2 "[X] ${FUNCNAME[0]}: invalid option: $OPTARG"
                HELP=2
                ;;
            *)
                echo >&2 "[X] ${FUNCNAME[0]}: unexpected input"
                declare -p opt OPTARG
                HELP=2
                ;;
        esac
    done
    shift $((OPTIND - 1))

    if [[ $HELP ]]; then
        dedent <<< "
            Print a bash function stacktrace
            Usage: ${FUNCNAME[0]} [-h] [-c CONTEXT] [-b BOTTOM] [-t TOP]

            Options:
            -c CONTEXT      print CONTEXT number of lines of context (currently $context)
            -b BOTTOM       trim BOTTOM frames from the bottom of the stack (currently $bottom)
            -t TOP          trim TOP frames from the top of the stack (currently $top)"
        return $HELP
    fi

    # echo ">> $(stack)"
    # echo ">> $(stackline)"
    #
    # for ((i = 0; i < ${#BASH_SOURCE[@]}; i++)); do
    #     # ((i == idx)) && echo -n " >> " || echo -n "    "
    #     echo "    ($i) ${BASH_LINENO[$i]} ${FUNCNAME[$i]} ${BASH_SOURCE[$i]}"
    # done

    echo "  Call stack (starting with oldest frame):"
    # iterating through 3 related arrays in reverse
    local idx
    for ((idx = ${#BASH_SOURCE[@]} - 1 - bottom; idx > top; idx--)); do
        showframe "${BASH_SOURCE[$idx]}" "${FUNCNAME[$idx]}" "${BASH_LINENO[$idx - 1]}"
    done
}

alias traceback='traceback "${BASH_SOURCE-}" "${FUNCNAME-}" "$LINENO" "$BASH_COMMAND" "$?"'
function traceback()
(
    set +euvx
    (($# == 5)) || return 2
    local filename=$1
    local funcname=$2
    local lineno=$3
    local command=$4
    local retval=$5

    stacktrace -t 2

    repeat '=' 20

    showframe "$filename" "$funcname" "$lineno"

    printf '>> %s (%s)\n' "$command" "$retval"
    read -rp "[press enter to continue] "
)

# inlist stacktrace "${_BASHLIB_FLAGS-}" && trap 'traceback' EXIT || true
