# bashlib utility
# shellcheck disable=2016,2059

inlist() {
    # test whether a path-like list contains an element
    # usage: inlist ELEMENT LIST
    [[ :$2: == *:"$1":* ]]
}

each() {
    # print each argument on a separate line
    # usage printeach [ELEMENT...]
    printeach "%s\n" "$@"
}

printeach() {
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

contains() {
    # whether or not an element appears in a list
    # usage: contains TARGET [ELEMENTS...]
    (($# >= 1)) || throw "Not enough arguments"

    local target=$1 && shift
    local item
    for item in "$@"; do
        [[ "$item" != "$target" ]] || return 0
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

valid_name() {
    # test whether a word is an acceptable variable name
    # usage: valid_name NAME...
    (($# >= 1)) || throw "Not enough arguments"
    while (($# >= 1)); do
        [[ $1 == [a-zA-Z_]*([a-zA-Z0-9_]) ]] || return 1
        shift
    done
}

declared() {
    # like [[ -v NAME ]], but for declarations
    # usage: declared NAME...
    (($# >= 1)) || throw "Not enough arguments"
    declare -p -- "$@" &> /dev/null
} && complete -v declared

attributes() {
    # print attributes of variables as understood by `declare`,
    # with the addition of 'u' to indicate "undefined"
    # usage: attributes NAME...
    (($# >= 1)) || throw "Not enough arguments"
    declare -p -- "$@" |& while IFS=$IFS:= read -r _ attrs _; do
        if [[ "$attrs" == declare ]]; then
            # got "bash: declare: <name>: not found"
            println u
        else
            println "${attrs#-}"
        fi
    done
} && complete -v attributes

quoted() {
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

_get_array() {
    # execute a command & read lines into an array
    # usage: get_array [READARRAY_ARGS...] ARRAY_NAME -- COMMAND [COMMAND_ARGS...]
    local -a readargs commandargs
    while (($# > 0)); do
        local arg=$1 && shift
        case $arg in
            --) commandargs=("$@") && break ;;
            *) readargs+=("$arg") ;;
        esac
    done

    ((${#commandargs[@]} >= 1)) || throw "No command given"

    # technically you could say something like `get_array -d : -- println $PATH`
    # and pass this check, but if you've gotten that far, i'll assume you know
    # what you're doing
    ((${#readargs[@]} >= 1)) || throw "No array name given"

    # execute the command
    local fulltext
    fulltext=$("${commandargs[@]}") || throw "Command execution failure${fulltext:+:$'\n'$fulltext}"

    # map the array
    readarray -t "${readargs[@]}" <<< "$fulltext"
}

get_array() {
    # execute a command & read lines into an array
    # usage: get_array ARRAY_NAME COMMAND [COMMAND_ARGS...]
    (($# >= 2)) || throw "Not enough arguments"

    local arrayref=$1 && shift
    local -a command=("$@")

    valid_name "$arrayref" || throw "Not a valid name: \"$arrayref\""

    # execute the command
    local fulltext
    fulltext=$("${command[@]}") || throw "Command execution failure${fulltext:+:$'\n'$fulltext}"

    # read lines into our array
    readarray -t "$arrayref" <<< "$fulltext"
}

from_list() {
    if [[ $# -ne 2 || $1 == -* ]]; then
        println "Convert a colon-separated list to a Bash array variable"
        println "Usage: ${FUNCNAME[0]} <ARRAY_NAME> <LIST>"
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

to_list() {
    if [[ $# -lt 1 || $1 == -* ]]; then
        println "Create a colon-separated list from zero or more elements"
        println "Usage: ${FUNCNAME[0]} <LIST_NAME> [ELEM...]"
        return 2
    fi

    local listref=$1 && shift
    valid_name "$listref" || throw "Not a valid name: \"$listref\""
    declared "$listref" || declare -g "$listref"

    IFS=: eval "$listref"='"$*"'
}

join() {
    # join strings
    # usage: join SEPARATOR [ELEMENTS...]

    (($# >= 1)) || throw "Not enough arguments"
    local sep=$1 && shift
    (($# >= 1)) || return 0

    print "$1" && shift
    printeach "${sep}%s" "$@"
    println
}

repeat() {
    # does something a bit like `TEXT * COUNT`
    # usage: repeat TEXT COUNT
    (($# == 2)) || throw "Wrong number of arguments"
    local text=$1 count=$2
    [[ $count == +([0-9]) ]] || throw "Not a number: $count"
    # apparently this is the fastest way to do this, for numbers both big and small...
    eval printf -- "'${text}%.0s'" "{1..$count}"
    println
}

prefix_lines() {
    # read from stdin and add a prefix to each line
    (($# == 1)) || throw "Wrong number of arguments"
    local prefix=$1 line
    while read -r line; do
        println "${prefix}${line}"
    done
}

indent() {
    # read from stdin and indent each line by `$1` spaces, (defaulting to 4)
    (($# <= 1)) || throw "Too many arguments"
    local width=${1:-4}
    [[ $width == +([0-9]) ]] || throw "Not a number: \"$width\""
    prefix_lines "$(repeat " " "$width")"
}

# shellcheck disable=2120
dedent() {
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
            [[ "${curr::$i}" == "${prefix::$i}" ]] || break
            common=${curr::$i}
        done

        # no match?
        if [[ ! ${common-} ]]; then
            printf >&2 "[!] ${FUNCNAME[0]}: No common prefix\n"
            printf >&2 "... (%s)\n" "$prefix_line" "$curr_line"

            prefix=
            break
        fi

        # update our collector value
        if [[ "$common" != "$prefix" ]]; then
            prefix=$common
            prefix_line=$curr_line
        fi
    done

    # trim and print each line
    println "${lines[@]#"$prefix"}"
}

_fixargs() {
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
                    split+=("-${1:$i:1}")
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

# shellcheck disable=2142  # "Aliases can't use positional parameters" that's fine
alias fixargs='eval "$(_fixargs "$@")"'

file_context() {
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

showframe() {
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

setopts() {
    # set shell options from a $SHELLOPTS-like list
    local STORE HELP USAGE
    local -a POSITIONAL
    while (($# > 0)); do
        local arg=$1 && shift
        case $arg in
            -h | --help) HELP=1 ;;
            -s | --store)
                if [[ -v 1 && $1 != @(-*|*:*) ]]; then
                    STORE=$1 && shift
                else
                    _err "Argument required: \"$arg\""
                    USAGE=1
                fi
                ;;
            -*) _err "Unrecognized option: \"$arg\"" && USAGE=1 ;;
            *) POSITIONAL+=("$arg") ;;
        esac
    done

    set -- "${POSITIONAL[@]}"

    local USAGE_TEXT="${FUNCNAME[0]} [--help] [--store NAME] OPTS_LIST"

    if [[ -v HELP ]]; then
        dedent <<< "
            ${FUNCNAME[0]}: set shell options from a \$SHELLOPTS-like list
            Usage: ${USAGE_TEXT}

            Options:

            -h | --help         print this message and halt
            -s | --store NAME   store original \$SHELLOPTS into variable NAME

            Parameters:

            OPTS_LIST           A colon-separated list of shell options
            "
        return 0
    fi

    local OPTS_LIST
    if (($# == 1)); then
        OPTS_LIST=$1
    else
        _err "Exactly 1 parameter expected"
        USAGE=1
    fi

    if [[ -v STORE ]] && ! valid_name "$STORE"; then
        _err "Invalid name: \"$STORE\""
        USAGE=1
    fi

    [[ -v USAGE ]] && throw "Usage: $USAGE_TEXT"

    if [[ -v STORE ]]; then
        eval "$STORE=$SHELLOPTS"
    fi

    local -a oldopts newopts
    from_list oldopts "$SHELLOPTS"
    from_list newopts "$OPTS_LIST"

    # shellcheck disable=2046
    set $(printf -- "+o %s " "${oldopts[@]}") $(printf -- "-o %s " "${newopts[@]}")
}

withflags() {
    # run a command with modified shell opts
    # usage: withflags [SHELLOPTS] -- COMMAND [ARGS]
    # ex: withflags -vx -- pathmunge PATH /usr/local/bin /usr/local/sbin

    local oldstate=$SHELLOPTS
    # set flags & positional arguments
    set "$@"
    local retval=0
    # execute (modified) positional arguments
    "$@" || retval=$?

    set +vx
    setopts "$oldstate"
    return $retval
}

arrayzip() {
    # merge arrays in a zipper fashion
    # usage: arrayzip DEST [SRC...]
    (($# >= 1)) || throw "Not enough arguments"

    local destref=$1 && shift
    valid_name "$destref" || throw "Invalid name: \"$destref\""

    # accumulate the lengths and values of our input arrays (collapsing sparse arrays)
    local -a _src_counts _src_values
    local srcref
    for srcref in "$@"; do
        valid_name "$srcref" || throw "Invalid name: \"$srcref\""
        eval "$(
            printf '_src_counts+=( "${#%s[@]}" )\n' "$srcref"
            printf '_src_values+=( "${%s[@]}" )\n' "$srcref"
        )"
    done

    # a temporary destination array
    local -a dest
    # the current index in our (abstract) source arrays
    local idx_s
    # the index in `_src_values` of the start of our current (abstract) source array
    local idx_v
    # the length of the current (abstract) source array
    local count
    # whether or not any source array has values remaining
    local any_remaining=1

    # iterate through our source arrays in parallel until no array has values remaining
    for ((idx_s = 0; any_remaining; idx_s++)); do
        any_remaining=0
        idx_v=0
        # iterate over our source arrays (by proxy)
        for count in "${_src_counts[@]}"; do
            # are there values left to collect in this source array?
            if ((idx_s < count)); then
                # collect the value at (start of current array) + (source array index)
                dest+=("${_src_values[idx_v + idx_s]}")
                any_remaining=1
            fi
            # move our `values` index past the end of the current source array
            ((idx_v += count))
        done
    done

    eval "$destref"'=("${dest[@]}")'
}
