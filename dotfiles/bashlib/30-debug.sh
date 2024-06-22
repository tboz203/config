# bash environment troubleshooting

# inspired by https://flokoe.github.io/bash-hackers-wiki/scripting/debuggingtips/#making-xtrace-more-useful
export PS4='+'$'\t''\e[02m${EPOCHREALTIME:+[$EPOCHREALTIME] }(${BASH_SOURCE:-main}:$LINENO${FUNCNAME:+:$FUNCNAME}): \e[0m'

alias _if_verbose='#'
alias _if_debug='#'
case ${_BASHLIB_LOGLEVEL-} in
    trace) ;&
    debug) alias _if_debug=' ' ;&
    verbose) alias _if_verbose=' ' ;&
    *) ;;
esac

inspect_var()
{
    (($# >= 1)) || throw "Not enough arguments"
    declare -p -- "$@" 2>&1 | indent >&2
}

# inlist replace_exec "${_BASHLIB_FLAGS-}" || return 0

replace_exec()
{
    # replace the `exec` builtin with a function that:
    # 1) displays the command to be executed, and pauses
    # 2) executes that command in a child process (i.e. NOT by the exec builtin)
    # 3) displays the result, and pauses
    # 4) exits
    # recommended usage: _if_verbose replace_exec

    # shellcheck disable=2317
    exec()
    {
        _if_verbose stackline
        _log "will run: $*" && pause
        local retval=0
        command "$@" || retval=$?
        _log "exited with $retval ($*)" && pause
        exit "$retval"
    }
}

# print_stack()
# {
#     local i=0
#     # println "$LINENO ${FUNCNAME[0]} ${BASH_SOURCE[0]}"
#     while caller $i; do ((i++)); done
# }
#
# stack()
# {
#     local line func file
#     print_stack | while read -r line func file; do
#         println "$func ($file:$line)"
#     done
# }

called-at()
{
    # like `caller` but with nicer formatting
    (($# <= 1)) || throw "Too many arguments"
    local idx=${1:-0}
    ((idx >= 0 && idx < ${#BASH_SOURCE[@]})) || return 1
    local funcname=${FUNCNAME[idx + 1]}
    local filename=${BASH_SOURCE[idx + 1]}
    local lineno=${BASH_LINENO[idx]}
    println "${funcname:+$funcname }(${filename:-main}:$lineno)"
}

stackline()
{
    local -a stackframes=()
    for ((i = ${#BASH_SOURCE[@]} - 1; i > 1; i--)); do
        stackframes+=("${FUNCNAME[$i]} (${BASH_SOURCE[$i]}:${BASH_LINENO[$i - 1]})")
    done

    ((${#stackframes[@]} >= 1)) || return 0

    print "${stackframes[0]}"

    local frame
    for frame in "${stackframes[@]:1}"; do
        print " > $frame"
    done

    println
}

showframe()
{
    (($# >= 3)) || throw "Not enough arguments"
    (($# <= 4)) || throw "Too many arguments"
    local filename=$1
    local funcname=$2
    local lineno=$3
    local context=${4-2}

    [[ $lineno == +([0-9]) ]] || throw "Not a number: $lineno"

    local -a lines
    file_context lines "$filename" "$lineno" "$context"

    println "    $filename:$lineno (in $funcname):"

    if ((${#lines[@]} == 0)); then
        println "   >> (not found)"
    else
        local ctx_lineno prefix
        for ctx_lineno in "${!lines[@]}"; do
            ((ctx_lineno == lineno)) && prefix="   >>" || prefix="     "
            println "$prefix $ctx_lineno ${lines[$ctx_lineno]}"
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
                _err "required argument not found: $OPTARG"
                HELP=2
                ;;
            ?)
                _err "invalid option: $OPTARG"
                HELP=2
                ;;
            *)
                _err "unexpected input"
                declare -p opt OPTARG
                HELP=2
                ;;
        esac
    done
    shift $((OPTIND - 1))

    if [[ ${HELP-} ]]; then
        dedent <<< "
            Print a bash function stacktrace
            Usage: ${FUNCNAME[0]} [-h] [-c CONTEXT] [-b BOTTOM] [-t TOP]

            Options:
            -c CONTEXT      print CONTEXT number of lines of context (currently $context)
            -b BOTTOM       trim BOTTOM frames from the bottom of the stack (currently $bottom)
            -t TOP          trim TOP frames from the top of the stack (currently $top)"
        return $HELP
    fi

    echo "  Call stack (starting with oldest frame):"
    # iterating through 3 related arrays in reverse
    local idx
    for ((idx = ${#BASH_SOURCE[@]} - 1 - bottom; idx > top; idx--)); do
        showframe "${BASH_SOURCE[$idx]}" "${FUNCNAME[$idx]}" "${BASH_LINENO[$idx - 1]}"
    done
}

_traceback()
{
    (($# == 5)) || throw "Wrong number of arguments"
    local filename=$1
    local funcname=$2
    local lineno=$3
    local command=$4
    local retval=$5

    stacktrace -t 2

    repeat '=' 20

    showframe "$filename" "$funcname" "$lineno"

    println ">> $command ($retval)"
    pause
} && alias traceback='_traceback "${BASH_SOURCE-}" "${FUNCNAME-}" "$LINENO" "$BASH_COMMAND" "$?"'

# inlist stacktrace "${_BASHLIB_FLAGS-}" && trap 'traceback' EXIT || true
