# bashlib utility
# shellcheck disable=2059

inlist()
{
    # test whether a path-like list contains an element
    # usage: inlist ELEMENT LIST
    [[ :$2: == *:"$1":* ]]
}

each()
{
    # print each argument separately
    printeach "%s\n" "$@"
}

printeach()
{
    # like printf, but does nothing without format arguments
    # usage: printeach FORMAT [ARG...]
    (($# >= 1)) || return 2
    (($# >= 2)) || return 0
    local format=$1 && shift
    printf "$format" "$@"
}

maybe()
{
    # run a command if it exists
    (($# >= 1)) || return 2
    havecmd "$1" || return 0
    "$@"
}

clone()
{
    # clone a variable
    # usage: clone SRC DST
    (($# == 2)) || return 2
    local src=$1
    local dst=$2
    [[ $src != "$dst" ]] || return 2

    local declaration
    read -r declaration <<< "$(declare -p "$src")"
    # strip off leading `declare \S+`
    declaration=${declaration#declare +([^[:space:]]) }
    eval "${declaration/$src/$dst}"
}

# array_remove()
# {
#     # remove each instance of an element from an array
#     # usage: array_remove ELEMENT ARRAY_NAME
#     (($# == 2)) || return 2
#     local target=$1
#     local arrayref=$2
# }

contains()
(
    # whether or not an element appears in a list
    # usage: contains TARGET [ELEMENTS...]
    (($# >= 1)) || return 2

    target=$1 && shift
    for item in "$@"; do
        [[ "$item" != "$target" ]] || return 0
    done
    return 1
)

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
#             printf '%s\n' "$key"
#             return 0
#         fi
#     done
#     return 1
# }

declared()
{
    # like [[ -v NAME ]], but for declarations
    (($# >= 1)) || return 2
    declare -p -- "$@" &> /dev/null
} && complete -v declared

attributes()
{
    # print attributes of variables as understood by `declare`,
    # with the addition of 'u' to indicate "undefined"
    (($# >= 1)) || return 2
    declare -p -- "$@" |& while IFS=$IFS:= read -r _ attrs _; do
        if [[ "$attrs" == declare ]]; then
            # got "bash: declare: <name>: not found"
            echo u
        else
            printf "%s\n" "${attrs#-}"
        fi
    done
} && complete -v attributes

quoted()
(
    set +vx
    for value in "$@"; do
        printf -v clean "%q" "$value"
        if [[ $value == "$clean" ]]; then
            # printf says no modifications needed; send the original
            printf "%s\n" "$value"
            continue
        fi

        if [[ $clean == \$* ]]; then
            # printf used $'...' notation; send the cleaned value
            printf "%s\n" "$clean"
            continue
        fi

        # otherwise, printf gave us the "escape\ every\ \$character\ form",
        # which we hate. we'll force it to use the other form, and then clean
        # up the result
        printf -v clean "%q" $'\n'"$value"
        printf "%s\n" "'${clean#\$\'\\n}"
    done
)

get_array()
{
    # execute a command & read lines into an array
    # usage: get_array [READARRAY_ARGS...] ARRAY -- COMMAND...
    local -a mapargs
    while (($# > 0)); do
        local arg=$1 && shift
        case $arg in
            --) break ;;
            *) mapargs+=("$arg") ;;
        esac
    done

    if (($# == 0)); then
        echo >&2 "[X] ${FUNCNAME[0]}: no command given"
        return 2
    elif ((${#mapargs[@]} == 0)); then
        # technically you could call like `get_array -d : -- echo $PATH` and
        # pass this check, but if you've gotten that far, i'll assume you know
        # what you're doing
        echo >&2 "[X] ${FUNCNAME[0]}: no array given"
        return 2
    fi

    # execute the command
    local fulltext
    fulltext=$("$@") || {
        local err=$?
        printf >&2 "%s\n" "$fulltext"
        return $err
    }

    # map the array
    readarray -t "${mapargs[@]}" <<< "$fulltext"
}

from_list()
{
    if [[ $# -ne 2 || $1 == -* ]]; then
        echo "Convert a colon-separated list to a Bash array variable"
        echo "Usage: ${FUNCNAME[0]} <ARRAY_NAME> <LIST>"
        return 2
    fi

    local arrayref=$1
    local list=$2

    [[ -n $arrayref ]] || return 2

    declared "${arrayref?}" || declare -ga "$arrayref" || return 1

    if [[ -z $list ]]; then
        eval "${arrayref?}=()"
    elif [[ $list == : ]]; then
        eval "${arrayref?}=('')"
    else
        # read into arrayref, splitting on `:`
        # (seems to use terminator semantics, so add an extra final separator)
        IFS=: read -r -d '' -a "${arrayref?}" < <(printf "%s" "${list}:") || true
    fi
}

to_list()
{
    if [[ $# -lt 1 || $1 == -* ]]; then
        echo "Create a colon-separated list from zero or more elements"
        echo "Usage: ${FUNCNAME[0]} <LIST_NAME> [ELEM...]"
        return 2
    fi

    local listref=$1 && shift
    [[ -n $listref ]] || return 2
    declared "$listref" || declare -g "$listref"

    IFS=: eval "$listref"='"$*"'
}

join()
{
    # join strings
    # usage: join SEPARATOR [ELEMENTS...]

    # no SEPARATOR?
    (($# >= 1)) || return 2
    local sep=$1 && shift
    # no ELEMENTS?
    (($# >= 1)) || return 0

    printf "%s" "$1"
    printeach "${sep}%s" "${@:1}"
    echo
}

repeat()
{
    # does something a bit like `TEXT * COUNT`
    # usage: repeat TEXT COUNT
    (($# == 2)) || return 2
    local text=$1 count=$2
    eval printf -- "'${text}%.0s'" "{1..$count}"
    echo
}

setpath()
{
    if (($# != 2)); then
        echo "Set a variable to a path if that path exists"
        echo "Usage: ${FUNCNAME[0]} VAR PATH"
        return 2
    fi
    [[ -e $2 ]] && export "$1=$2"
}

sourcepath()
{
    if [[ $# -ne 1 || $1 == -* ]]; then
        echo "Source a script if it exists"
        echo "Usage: ${FUNCNAME[0]} PATH"
        return 2
    elif [[ -e $1 ]]; then
        source "$1"
    fi
} && complete -f sourcepath

indent()
(
    # indent each line by $1 (or 4)
    set +vx
    local width=${1:-4}
    local line
    while read -r line; do
        printf "%${width}s%s\n" "" "$line"
    done
)

dedent()
(
    # trim common leading whitespace from non-blank lines

    set +vx
    (($# == 0)) || return 2
    readarray -t lines
    # short-circuit for empty stdin
    ((${#lines[@]} > 0)) || return 0

    # find the common leading whitespace between all non-blank lines
    for curr_line in "${lines[@]}"; do
        # skip blank lines
        [[ $curr_line != *([[:space:]]) ]] || continue

        # strip largest trailing substring that starts with non-whitespace
        curr="${curr_line%%[^[:space:]]*}"

        # if prefix hasn't been set yet, set it & continue to next line
        if [[ -z ${prefix-} ]]; then
            prefix=$curr
            prefix_line=$curr_line
            continue
        fi

        # find longest common prefix
        for ((i = 1; i <= ${#prefix}; i++)); do
            [[ "${curr::$i}" == "${prefix::$i}" ]] || break
            common=${curr::$i}
        done

        # no match?
        if [[ -z ${common-} ]]; then
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
    printf "%s\n" "${lines[@]#"$prefix"}"
)

fixargs()
(
    set +vx
    arguments=()
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
                split=()
                for ((i = 1; i < ${#1}; i++)); do
                    split+=("-${1:$i:1}")
                done
                set -- "${split[@]}" "${@:2}"
                ;;
            *)
                # others unmodified
                arguments+=("$(quoted "$1")") && shift
                ;;
        esac
    done
    echo set -- "${arguments[@]}"
)

file_context()
{
    # read lines from $filename at $lineno with $context lines of context
    # lines are read into sparse array $lines such that array indicies match file line numbers
    # usage: filename=FILENAME lineno=LINENO [context=CONTEXT] file_context
    # mapfile -s $((lineno - context - 1)) -O $((lineno - context)) -n $((context * 2 + 1)) -t lines < "$filename"

    # no function arguments allowed, only environment variables
    [[ $# -eq 0 && -n ${filename-} && -n ${lineno-} ]] || return 1

    ((lineno >= 1)) || lineno=1
    [[ -n ${context-} ]] || context=2

    # max(lineno - context, 1)
    local start=$((lineno > context ? lineno - context : 1))
    # context before + line itself + context after (adjusted when at start of file)
    local count=$((context * 2 + 1 - (lineno > context ? 0 : context + 1 - lineno)))

    declared lines || declare -ga lines
    lines=()

    mapfile -t -O $start -n $count -s $((start - 1)) lines < "$filename"
}
