# bash environment troubleshooting

# inspired by https://flokoe.github.io/bash-hackers-wiki/scripting/debuggingtips/#making-xtrace-more-useful
export PS4='+\011\e[02m${EPOCHREALTIME:+[$EPOCHREALTIME] }(${BASH_SOURCE:-main}:$LINENO${FUNCNAME:+:$FUNCNAME}): \e[0m'

alias _if_verbose='true #'
alias _if_debug=': #'
case ${_BASHLIB_LOGLEVEL-} in
    trace) ;&
    debug) alias _if_debug=' ' ;&
    verbose) alias _if_verbose=' ' ;&
    *) ;;
esac

inspect_var() {
    (($# >= 1)) || throw "Not enough arguments"
    declare -p -- "$@" 2>&1 | indent >&2
}

replace_exec() {
    # replace the `exec` builtin with a function that:
    # 1) displays the command to be executed, and pauses
    # 2) executes that command in a child process (i.e. NOT by the exec builtin)
    # 3) displays the result, and pauses
    # 4) exits
    # recommended usage: _if_verbose replace_exec

    # shellcheck disable=2317
    exec() {
        _if_verbose stackline
        _log "will run: $*"
        pause || throw "Interrupted"
        local retval=0
        command "$@" || retval=$?
        _log "exited with $retval ($*)"
        pause || throw "Interrupted"
        exit "$retval"
    }
}

print_stack() {
    local i=0
    # println "$LINENO ${FUNCNAME[0]} ${BASH_SOURCE[0]}"
    while caller $i; do ((i++)); done
}

stack() {
    local line func file
    print_stack | while read -r line func file; do
        println "$func ($file:$line)"
    done
}

called-at() {
    # like `caller` but with nicer formatting
    (($# <= 1)) || throw "Too many arguments"
    local idx=${1:-0}
    ((idx >= 0 && idx < ${#BASH_SOURCE[@]})) || return 1
    local funcname=${FUNCNAME[idx + 1]}
    local filename=${BASH_SOURCE[idx + 1]}
    local lineno=${BASH_LINENO[idx]}
    println "${funcname:+$funcname }(${filename:-main}:$lineno)"
}

stackline() {
    local -a stackframes
    for ((i = ${#BASH_SOURCE[@]} - 1; i > 1; i--)); do
        stackframes+=("${FUNCNAME[$i]} (${BASH_SOURCE[$i]}:${BASH_LINENO[i - 1]})")
    done

    join " > " "${stackframes[@]}"
}

stacktrace() {
    # print the current call stack
    local context=2 top=0 bottom=0

    local opt OPTARG OPTIND HELP USAGE
    while getopts :hc:t:b: opt; do
        case $opt in
            h) HELP=1 ;;
            c) context=$OPTARG ;;
            t) top=$OPTARG ;;
            b) bottom=$OPTARG ;;
            :)
                _err "required argument not found: $OPTARG"
                USAGE=1
                ;;
            ?)
                _err "invalid option: $OPTARG"
                USAGE=1
                ;;
            *)
                _err "unexpected input"
                declare -p opt OPTARG
                USAGE=1
                ;;
        esac
    done
    shift $((OPTIND - 1))

    local USAGE_TEXT="${FUNCNAME[0]} [-h] [-c CONTEXT] [-b BOTTOM] [-t TOP]"

    if [[ ${HELP-} ]]; then
        dedent <<< "
            Print a bash function stacktrace
            Usage: $USAGE_TEXT

            Options:
            -c CONTEXT      print CONTEXT number of lines of context (currently $context)
            -b BOTTOM       trim BOTTOM frames from the bottom of the stack (currently $bottom)
            -t TOP          trim TOP frames from the top of the stack (currently $top)"
        return 0
    fi

    if [[ ${USAGE-} ]]; then
        echo "Usage: $USAGE_TEXT"
        return 2
    fi

    ((bottom = ${#BASH_SOURCE[@]} - 1 - bottom))
    ((bottom > top)) || return 0

    echo "  Call stack (starting with oldest frame):"
    # iterating through 3 related arrays in reverse
    local idx
    for ((idx = bottom; idx > top; idx--)); do
        showframe "${BASH_SOURCE[$idx]}" "${FUNCNAME[$idx]}" "${BASH_LINENO[idx - 1]}"
    done
}

_traceback() {
    local last_status=$?
    if (($# != 5)); then
        _err "Wrong number of arguments"
        return $last_status
    fi

    local filename=$1
    local funcname=$2
    local lineno=$3
    local command=$4
    local retval=$5

    # stacktrace -t 2
    stacktrace
    inspect_var filename funcname lineno command retval
    inspect_var BASH_SOURCE FUNCNAME BASH_LINENO

    if [[ $lineno == 1 ]]; then
        # called from `trap`
        trap - ERR EXIT
    else
        repeat '=' 20
        showframe "$filename" "$funcname" "$lineno"
    fi

    echo ">> $command ($retval)"

    pause || throw "Interrupted"
    return $last_status
} && alias traceback='_traceback "${BASH_SOURCE-}" "${FUNCNAME-}" "$LINENO" "$BASH_COMMAND" "$?"'

[[ :${_BASHLIB_FLAGS-}: != *:stacktrace:* ]] || trap 'traceback' ERR EXIT

mtime() {
    # time a statement with microsecond precision (accuracy not guaranteed 😬)
    local start=$EPOCHREALTIME stop retval=0
    "$@" || retval=$?
    stop=$EPOCHREALTIME
    bc <<< "$stop - $start"
    return $retval
}

nested() {
    (($# >= 2)) || throw "Not enough arguments"
    local depth=${1:?0} && shift
    if ((depth > 0)); then
        nested $((depth - 1)) "$@"
    else
        "$@"
    fi
}
