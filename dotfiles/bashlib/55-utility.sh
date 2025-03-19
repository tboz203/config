# bashlib utility
# shellcheck disable=2016,2059

function inlist {
    # test whether a path-like list contains an element
    # usage: inlist ELEMENT LIST
    [[ :$2: == *:"$1":* ]]
}

if ((BASH_VERSINFO[0] >= 5)); then
    function wraplist {
        # Convert an unwrapped list (like $PATH) to a wrapped list (like :$PATH:)
        if [[ $# != 2 || ${1-} == -* ]]; then
            _err "Convert an unwrapped list to a wrapped list"
            _err "Usage: ${FUNCNAME[0]} NAME LIST"
            return 2
        fi

        local -n name=$1 && shift
        local list=$1 && shift

        case $list in
            "") name=: ;;
            :) name=:: ;;
            *) name=":$list:" ;;
        esac
    }
else
    function wraplist {
        # Convert an unwrapped list (like $PATH) to a wrapped list (like :$PATH:)
        if [[ $# != 2 || ${1-} == -* ]]; then
            _err "Convert an unwrapped list to a wrapped list"
            _err "Usage: ${FUNCNAME[0]} NAME LIST"
            return 2
        fi

        local name=$1 && shift
        local list=$1 && shift

        valid_name "$name" || throw "Not a valid name: \"$name\""

        case $list in
            "") eval "$name=:" ;;
            :) eval "$name=::" ;;
            *) eval "$name=:$list:" ;;
        esac
    }
fi

if ((BASH_VERSINFO[0] >= 5)); then
    function unwraplist {
        # Convert a wrapped list (like :$PATH:) to an unwrapped list (like $PATH)
        if [[ $# != 2 || ${1-} == -* ]]; then
            _err "Convert a wrapped list to an unwrapped list"
            _err "Usage: ${FUNCNAME[0]} NAME LIST"
            return 2
        fi

        local -n name=$1 && shift
        local list=$1 && shift

        case $list in
            # empty list
            :) name="" ;;
            # list with a single null entry
            ::) name=: ;;
            # any other wrapped list
            :*:)
                list=${list%:} && list=${list#:}
                name="$list"
                ;;
            # something else
            *) throw "Invalid list: \"$list\"" ;;
        esac
    }
else
    function unwraplist {
        # Convert a wrapped list (like :$PATH:) to an unwrapped list (like $PATH)
        if [[ $# != 2 || ${1-} == -* ]]; then
            _err "Convert a wrapped list to an unwrapped list"
            _err "Usage: ${FUNCNAME[0]} NAME LIST"
            return 2
        fi

        local name=$1 && shift
        local list=$1 && shift

        valid_name "$name" || throw "Not a valid name: \"$name\""

        case $list in
            # empty list
            :) eval "$name=" ;;
            # list with a single null entry
            ::) eval "$name=:" ;;
            # any other wrapped list
            :*:)
                list=${list%:} && list=${list#:}
                eval "$name='$list'"
                ;;
            # something else
            *) throw "Invalid list: \"$list\"" ;;
        esac
    }
fi

function each {
    # print each argument on a separate line
    # usage printeach [ELEMENT...]
    printeach "%s\n" "$@"
}

function printeach {
    # like printf, but does nothing without format arguments
    # usage: printeach FORMAT [ARG...]
    (($# >= 1)) || throw "Not enough arguments"
    (($# >= 2)) || return 0
    local format=$1 && shift
    printf "$format" "$@"
}

# array_remove()
# {
#     # remove each instance of an element from an array
#     # usage: array_remove ELEMENT ARRAY_NAME
#     (($# == 2)) || return 2
#     local target=$1
#     local arrayref=$2
# }

function contains {
    # whether or not an element appears in a list
    # usage: contains TARGET [ELEMENTS...]
    (($# >= 1)) || throw "Not enough arguments"

    local target=$1 && shift
    local item
    for item in "$@"; do
        [[ $item != "$target" ]] || return 0
    done
    return 1
}

# array_index()
# {
#     # print the key of an element in an array
#     # if the element is not found, prints nothing and returns 1
#     # usage: contains ELEMENT ARRAY_NAME
#     (($# >= 1)) || return 2
#
#     local target=$1
#     local arrayref=$2
#
#     local array
#     clone "$arrayref" array
#
#     local key value
#     for key in "${!array[@]}"; do
#         value=${array[$key]}
#         if [[ $target == "$value" ]]; then
#             println "$key"
#             return 0
#         fi
#     done
#     return 1
# }

function declared {
    # like [[ -v NAME ]], but for declarations
    # usage: declared NAME...
    (($# >= 1)) || throw "Not enough arguments"
    declare -p -- "$@" &> /dev/null
} && complete -v declared

function quoted {
    # print each argument on a separate line, quoted if necessary
    # usage: quoted [ARG...]
    local -a results
    local value clean
    for value in "$@"; do
        printf -v clean "%q" "$value"
        if [[ $value == "$clean" ]]; then
            # printf says no modifications needed
            results+=("$value")
        elif [[ $clean == \$* ]]; then
            # printf used $'...' notation; send the cleaned value
            results+=("$clean")
        else
            # otherwise, printf gave us the "escape\ every\ \$character\ form",
            # which we hate. we'll force it to use the other form, and then clean
            # up the result
            printf -v clean "%q" $'\n'"$value"
            results+=("'${clean#\$\'\\n}")
        fi
    done
    each "${results[@]}"
}

if ((BASH_VERSINFO[0] < 5)); then
    function attributes {
        # print attributes of variables as understood by `declare`,
        # with the addition of 'u' to indicate "undefined"
        # usage: attributes NAME...
        (($# >= 1)) || throw "Not enough arguments"
        declare -p -- "$@" |& while IFS=$IFS:= read -r _ attrs _; do
            if [[ $attrs == declare ]]; then
                # got "bash: declare: <name>: not found"
                println u
            else
                println "${attrs#-}"
            fi
        done
    } && complete -v attributes

    function valid_name {
        # test whether a word is an acceptable variable name
        # usage: valid_name NAME...
        (($# >= 1)) || throw "Not enough arguments"
        while (($#)); do
            [[ $1 == [a-zA-Z_]*([a-zA-Z0-9_]) ]] || return 1
            shift
        done
    }
fi

if ((BASH_VERSINFO[0] >= 5)); then
    function get_array {
        # execute a command & read lines into an array
        # usage: get_array ARRAY_NAME COMMAND [COMMAND_ARGS...]
        (($# >= 2)) || throw "Not enough arguments"

        local -n arrayref=$1 && shift
        local -a command=("$@")

        # execute the command
        local fulltext
        fulltext=$("${command[@]}") || throw "Command failed ($(printf '%q ' "${command[@]}")): $?${fulltext:+:$'\n'$fulltext}"

        # read lines into our array
        readarray -t arrayref <<< "$fulltext"
    }
else
    function get_array {
        # execute a command & read lines into an array
        # usage: get_array ARRAY_NAME COMMAND [COMMAND_ARGS...]
        (($# >= 2)) || throw "Not enough arguments"

        local arrayref=$1 && shift
        local -a command=("$@")

        valid_name "$arrayref" || throw "Not a valid name: \"$arrayref\""

        # execute the command
        local fulltext
        fulltext=$("${command[@]}") || throw "Command failed ($(printf '%q ' "${command[@]}")): $?${fulltext:+:$'\n'$fulltext}"

        # read lines into our array
        readarray -t "$arrayref" <<< "$fulltext"
    }
fi

if ((BASH_VERSINFO[0] >= 5)); then
    function from_list {
        if [[ $# -ne 2 || ${1-} == -* ]]; then
            _err "Convert a colon-separated list to a Bash array variable"
            _err "Usage: ${FUNCNAME[0]} <ARRAY_NAME> <LIST>"
            return 2
        fi

        local -n arrayref=$1
        local list=$2

        if [[ -v $list ]]; then
            # looks like a variable name; let's dereference it
            list=${!list}
        fi

        case $list in
            "") arrayref=() ;;
            :) arrayref=('') ;;
            *)
                # read into arrayref, splitting on `:`
                # (seems to use terminator semantics, so add an extra final separator)
                IFS=: read -r -d '' -a arrayref < <(print "${list}:") || true
                ;;
        esac
    }
else
    function from_list {
        if [[ $# -ne 2 || ${1-} == -* ]]; then
            _err "Convert a colon-separated list to a Bash array variable"
            _err "Usage: ${FUNCNAME[0]} <ARRAY_NAME> <LIST>"
            return 2
        fi

        local arrayref=$1
        local list=$2

        valid_name "$arrayref" || throw "Not a valid array name: \"$arrayref\""

        declared "$arrayref" || declare -ga "$arrayref" || return 1

        case $list in
            "") eval "$arrayref=()" ;;
            :) eval "$arrayref=('')" ;;
            *)
                # read into arrayref, splitting on `:`
                # (seems to use terminator semantics, so add an extra final separator)
                IFS=: read -r -d '' -a "$arrayref" < <(print "${list}:") || true
                ;;
        esac
    }
fi

if ((BASH_VERSINFO[0] >= 5)); then
    function to_list {
        if [[ $# -lt 1 || ${1-} == -* ]]; then
            _err "Create a colon-separated list from zero or more elements"
            _err "Usage: ${FUNCNAME[0]} <LIST_NAME> [ELEM...]"
            return 2
        fi

        local -n listref=$1 && shift
        local IFS=:
        listref="$*"
    }
else
    function to_list {
        if [[ $# -lt 1 || ${1-} == -* ]]; then
            _err "Create a colon-separated list from zero or more elements"
            _err "Usage: ${FUNCNAME[0]} <LIST_NAME> [ELEM...]"
            return 2
        fi

        local listref=$1 && shift
        valid_name "$listref" || throw "Not a valid name: \"$listref\""
        declared "$listref" || declare -g "$listref"

        IFS=: eval "$listref"='"$*"'
    }
fi

function join {
    # join strings
    # usage: join SEPARATOR [ELEMENTS...]

    (($# >= 1)) || throw "Not enough arguments"
    local sep=$1 && shift
    (($# >= 1)) || return 0

    print "$1" && shift
    printeach "${sep}%s" "$@"
    println
}

function repeat {
    # does something a bit like `TEXT * COUNT`
    # usage: repeat TEXT COUNT
    (($# == 2)) || throw "Wrong number of arguments"
    local text=$1 count=$2
    [[ $count == +([0-9]) ]] || throw "Not a number: $count"
    # apparently this is the fastest way to do this, for numbers both big and small...
    eval printf -- "'${text}%.0s'" "{1..$count}"
    println
}

function prefix_lines {
    # read from stdin and add a prefix to each line
    (($# == 1)) || throw "Wrong number of arguments"
    local prefix=$1 line
    while read -r line; do
        println "${prefix}${line}"
    done
}

function indent {
    # read from stdin and indent each line by `$1` spaces, (defaulting to 4)
    (($# <= 1)) || throw "Too many arguments"
    local width=${1:-4}
    [[ $width == +([0-9]) ]] || throw "Not a number: \"$width\""
    prefix_lines "$(repeat " " "$width")"
}

# shellcheck disable=2120
function dedent {
    # read from stdin and trim common leading whitespace (from non-blank lines)

    (($# == 0)) || throw "No arguments permitted"
    local -a lines
    readarray -t lines
    # short-circuit for empty stdin
    ((${#lines[@]} > 0)) || return 0

    # find the common leading whitespace between all non-blank lines
    local prefix prefix_line
    local curr curr_line
    for curr_line in "${lines[@]}"; do
        # skip blank lines
        [[ $curr_line != *([[:space:]]) ]] || continue

        # strip largest trailing substring that starts with non-whitespace
        curr=${curr_line%%[^[:space:]]*}

        # if prefix hasn't been set yet, set it & continue to next line
        if [[ ! ${prefix-} ]]; then
            prefix=$curr
            prefix_line=$curr_line
            continue
        fi

        # find longest common prefix
        local common=
        for ((i = 1; i <= ${#prefix}; i++)); do
            [[ ${curr::i} == "${prefix::i}" ]] || break
            common=${curr::i}
        done

        # no match?
        if [[ ! ${common-} ]]; then
            printf >&2 "[!] ${FUNCNAME[0]}: No common prefix\n"
            printf >&2 "... (%s)\n" "$prefix_line" "$curr_line"

            prefix=
            break
        fi

        # update our collector value
        if [[ $common != "$prefix" ]]; then
            prefix=$common
            prefix_line=$curr_line
        fi
    done

    # trim and print each line
    println "${lines[@]#"$prefix"}"
}

if ((BASH_VERSINFO[0] >= 5)); then
    function fixargs {
        local -a arguments
        while (($#)); do
            case $1 in
                --)
                    # halt argument parsing; take all remaining args verbatim
                    arguments+=("$@") && break
                    ;;
                -*=*)
                    # split --var=value pairs, preserving whitespace, and re-consider
                    set -- "${1%%=*}" "${1#*=}" "${@:2}"
                    ;;
                -[^-]?*)
                    # split `-xyz` flags into `-x -y -z`, and re-consider
                    local split=()
                    for ((i = 1; i < ${#1}; i++)); do
                        split+=("-${1:i:1}")
                    done
                    set -- "${split[@]}" "${@:2}"
                    ;;
                *)
                    # others unmodified
                    arguments+=("$1") && shift
                    ;;
            esac
        done
        echo set -- "${arguments[@]@Q}"
    }
else
    function fixargs {
        local -a arguments
        while (($#)); do
            case $1 in
                --)
                    # halt argument parsing; take all remaining args verbatim
                    arguments+=("$@") && break
                    ;;
                -*=*)
                    # split --var=value pairs, preserving whitespace, and re-consider
                    set -- "${1%%=*}" "${1#*=}" "${@:2}"
                    ;;&
                -[^-]?*)
                    # split `-xyz` flags into `-x -y -z`, and re-consider
                    local split=()
                    for ((i = 1; i < ${#1}; i++)); do
                        split+=("-${1:i:1}")
                    done
                    set -- "${split[@]}" "${@:2}"
                    ;;
                *)
                    # others unmodified
                    arguments+=("$1") && shift
                    ;;
            esac
        done

        ((${#arguments[0]} >= 1)) || return 0

        get_array arguments quoted "${arguments[@]}"
        echo set -- "${arguments[@]}"
    }
fi

# shellcheck disable=2142  # "Aliases can't use positional parameters" that's fine
alias fixargs='eval "$(\fixargs "$@")"'

if ((BASH_VERSINFO[0] >= 5)); then
    function file_context {
        # read lines from $filename at $lineno with $context lines of context
        # lines are read into sparse array $lines such that array indicies match file line numbers
        # usage: file_context ARRAY_NAME FILENAME LINENO [CONTEXT]

        (($# >= 3)) || throw "Not enough arguments"
        (($# <= 4)) || throw "Too many arguments"
        local -n arrayref=$1
        local filename=$2
        local lineno=$3
        local context=${4:-2}

        ((lineno >= 0)) || throw "Invalid line number: $lineno"
        ((lineno >= 1)) || lineno=1

        # first line number: max(lineno - context, 1)
        local start=$((lineno > context ? lineno - context : 1))
        # max number of lines to read: the line itself, plus leading context, plus trailing context
        local count=$((1 + (lineno - start) + context))

        mapfile -t -O $start -n $count -s $((start - 1)) arrayref < "$filename" &> /dev/null
    }
else
    function file_context {
        # read lines from $filename at $lineno with $context lines of context
        # lines are read into sparse array $lines such that array indicies match file line numbers
        # usage: file_context ARRAY_NAME FILENAME LINENO [CONTEXT]

        (($# >= 3)) || throw "Not enough arguments"
        (($# <= 4)) || throw "Too many arguments"
        local arrayref=$1
        local filename=$2
        local lineno=$3
        local context=${4:-2}

        valid_name arrayref || throw "Not a valid array name: \"$arrayref\""

        ((lineno >= 0)) || throw "Invalid line number: $lineno"
        ((lineno >= 1)) || lineno=1

        # first line number: max(lineno - context, 1)
        local start=$((lineno > context ? lineno - context : 1))
        # max number of lines to read: the line itself, plus leading context, plus trailing context
        local count=$((1 + (lineno - start) + context))

        declared "${arrayref:?}" || declare -ga "${arrayref:?}"
        eval "${arrayref:?}=()"

        mapfile -t -O $start -n $count -s $((start - 1)) "${arrayref:?}" < "$filename" &> /dev/null
    }
fi

function showframe {
    # display a bash function "frame"
    # e.g: $ showframe ~/.bashrc my_function 10
    #     ~/.bashrc:10 (in my_function):
    #       8     shopt -s checkhash
    #       9
    #    >> 10     local item
    #       11     for item in ~/.bash_init/*; do
    #       12         if [[ $item == *.sh ]]; then

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

function setopts {
    if [[ $# != 1 || $1 == -* ]]; then
        _err "Set shell options from a SHELLOPTS-like list"
        _err "Usage: ${FUNCNAME[0]} NAME LIST"
        return 2
    fi

    local OPTS_LIST=$1

    local -a OLDOPTS NEWOPTS CHANGES
    from_list OLDOPTS "$SHELLOPTS"
    from_list NEWOPTS "$OPTS_LIST"

    local oldopt newopt
    # iterate through both lists to find added & removed options
    while ((${#OLDOPTS[@]} || ${#NEWOPTS[@]})); do
        oldopt=${OLDOPTS[0]}
        newopt=${NEWOPTS[0]}
        _if_debug inspect_var oldopt newopt OLDOPTS NEWOPTS
        if [[ $oldopt == "$newopt" ]]; then
            # opt is unchanged; skip it
            OLDOPTS=("${OLDOPTS[@]:1}")
            NEWOPTS=("${NEWOPTS[@]:1}")
        elif [[ $oldopt && $oldopt < $newopt ]]; then
            # $oldopt is not in ${NEWOPTS[@]}; disable it
            CHANGES+=(+o "$oldopt")
            OLDOPTS=("${OLDOPTS[@]:1}")
        else
            # $newopt is not in ${OLDOPTS[@]}; enable it
            CHANGES+=(-o "$newopt")
            NEWOPTS=("${NEWOPTS[@]:1}")
        fi
    done

    ((!${#CHANGES[@]})) || set "${CHANGES[@]}"
}

function withflags {
    # run a command with modified shell opts
    # usage: withflags [SHELLOPTS] -- COMMAND [ARGS]
    # ex: withflags -vx -- pathmunge PATH /usr/local/bin /usr/local/sbin

    local OLDSTATE=$SHELLOPTS
    # set flags & positional arguments
    set "$@"
    local RETVAL=0
    # execute (modified) positional arguments
    "$@" || RETVAL=$?

    set +vx
    setopts "$OLDSTATE"
    return $RETVAL
}

# function arrayzip {
#     # merge arrays in a zipper fashion
#     # usage: arrayzip DEST [SRC...]
#     (($# >= 1)) || throw "Not enough arguments"
#
#     local destref=$1 && shift
#     valid_name "$destref" || throw "Invalid name: \"$destref\""
#
#     # accumulate the lengths and values of our input arrays (collapsing sparse arrays)
#     local -a _src_counts _src_values
#     local srcref
#     for srcref in "$@"; do
#         valid_name "$srcref" || throw "Invalid name: \"$srcref\""
#         eval "$(
#             printf '_src_counts+=( "${#%s[@]}" )\n' "$srcref"
#             printf '_src_values+=( "${%s[@]}" )\n' "$srcref"
#         )"
#     done
#
#     # a temporary destination array
#     local -a dest
#     # the current index in our (abstract) source arrays
#     local idx_s
#     # the index in `_src_values` of the start of our current (abstract) source array
#     local idx_v
#     # the length of the current (abstract) source array
#     local count
#     # whether or not any source array has values remaining
#     local any_remaining=1
#
#     # iterate through our source arrays in parallel until no array has values remaining
#     for ((idx_s = 0; any_remaining; idx_s++)); do
#         any_remaining=0
#         idx_v=0
#         # iterate over our source arrays (by proxy)
#         for count in "${_src_counts[@]}"; do
#             # are there values left to collect in this source array?
#             if ((idx_s < count)); then
#                 # collect the value at (start of current array) + (source array index)
#                 dest+=("${_src_values[idx_v + idx_s]}")
#                 any_remaining=1
#             fi
#             # move our `values` index past the end of the current source array
#             ((idx_v += count))
#         done
#     done
#
#     eval "$destref"'=("${dest[@]}")'
# }

# function patchfunc {
#     # modify a function
#     throw "Not Implemented"
# }

function pause {
    # pause for user
    local rc=0 REPLY
    read -rsp "[Press enter to contine] " || rc=$?
    echo
    return $rc
}

