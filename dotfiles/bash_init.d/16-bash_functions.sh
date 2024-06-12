# .bash_functions
# vim: filetype=sh tabstop=4 shiftwidth=0 softtabstop=-1 expandtab
# shellcheck disable=SC2016,2059

inlist()
{
    # test whether a path-like list contains an element
    # usage: inlist ELEMENT LIST
    [[ :$2: == *:"$1":* ]]
}

maybe()
{
    # run a command if it exists
    (($# > 0)) || return 1
    if havecmd "$1"; then
        "$@" || local retval=$?
    fi
    return "${retval:-0}"
}

contains()
(
    # whether or not an element appears in a list
    # usage: contains TARGET [ELEMENTS...]
    if (($# < 1)); then
        echo >&2 "[X] ${FUNCNAME[0]}: no values provided"
        return 1
    fi

    target=$1 && shift
    for item in "$@"; do
        [[ "$item" == "$target" ]] && return 0
    done
    return 1
)

declared()
{
    # like [[ -v NAME ]], but for declarations
    (($# > 0)) && declare -p "$@" &> /dev/null
} && complete -v declared

attributes()
{
    # print attributes of variables as understood by `declare`,
    # with the addition of 'u' to indicate "undefined"
    (($# > 0)) || return 1
    declare -p -- "$@" |& while IFS=$IFS:= read -r _ attrs _; do
        if [[ "$attrs" == declare ]]; then
            # got "bash: declare: <name>: not found"
            echo u
        else
            echo "${attrs#-}"
        fi
    done
} && complete -v attributes

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
        return 1
    elif ((${#mapargs[*]} == 0)); then
        # technically you could call like `get_array -d : -- echo $PATH` and
        # pass this check, but if you've gotten that far, i'll assume you know
        # what you're doing
        echo >&2 "[X] ${FUNCNAME[0]}: no array given"
        return 1
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
    if (($# != 2)); then
        echo "Convert a colon-separated list to a Bash array variable"
        echo "Usage: ${FUNCNAME[0]} <ARRAY_NAME> <LIST>"
        return 1
    fi

    local -n arrayref=$1 || return
    local list=$2

    declared "${!arrayref}" || declare -ga "${!arrayref}"

    if [[ -z $list ]]; then
        arrayref=()
    elif [[ $list == : ]]; then
        arrayref=("")
    else
        # read into arrayref, splitting on `:`
        # (`read` uses terminator semantics, so add an extra final separator)
        IFS=: read -ra arrayref <<< "${list}:"
    fi
}

to_list()
{
    if [[ $# -lt 1 || $1 == -* ]]; then
        echo "Create a colon-separated list from zero or more elements"
        echo "Usage: ${FUNCNAME[0]} <LIST_NAME> [ELEM...]"
        return 1
    fi

    local -n listref=$1 && shift || return
    declared "${!listref}" || declare -g "${!listref}"

    local IFS=:
    listref="$*"
}

join()
{
    # join strings
    # usage: join SEPARATOR [ELEMENTS...]

    # no SEPARATOR?
    (($# > 0)) || return 1
    local sep=$1 && shift
    # no ELEMENTS?
    (($# > 0)) || return 0

    printf "%s" "$1" && shift
    printf "${sep}%s" "$@"
    printf "\n"
}

repeat()
{
    # does something a bit like `TEXT * COUNT`
    # usage: repeat TEXT COUNT
    (($# == 2)) || return 1
    local text=$1 count=$2
    eval printf -- "'${text}%.0s'" "{1..$count}"
    printf "\n"
}

setpath()
{
    if (($# != 2)); then
        echo "Set a variable to a path if that path exists"
        echo "Usage: ${FUNCNAME[0]} VAR PATH"
        return 1
    fi
    [[ -e $2 ]] && export "$1=$2"
}

sourcepath()
{
    if [[ $# -ne 1 || $1 == -* ]]; then
        echo "Source a script if it exists"
        echo "Usage: ${FUNCNAME[0]} PATH"
        return 1
    elif [[ -e $1 ]]; then
        source "$1"
    fi
} && complete -f sourcepath

each()
{
    printf "%s\n" "$@"
}

trim()
(
    readarray -t lines

    # short-circuit for empty stdin
    ((${#lines[@]} > 0)) || return

    # find the common leading whitespace between all non-blank lines
    for curr_line in "${lines[@]}"; do
        # skip blank lines
        [[ ! $curr_line =~ ^[[:space:]]*$ ]] || continue

        # strip largest trailing substring that starts with non-whitespace
        curr="${curr_line%%[^[:space:]]*}"

        # if prefix hasn't been set yet, set it & continue to next line
        if [[ ! -v prefix ]]; then
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
            printf >&2 "[!] ${FUNCNAME[0]}: No common prefix"
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

# map()
# {
#     local -a template
#     local item
#     for item in "$@"; do
#         [[ $item != -- ]] || break
#         template+=("$item") && shift
#     done
#
#     if [[ ${1-} != -- ]]; then
#         echo "[X] ${FUNCNAME[0]}: no command arguments given"
#         return 1
#     fi
#
#     [[ "${template[*]}" == *%s* ]] || template+=("%s")
#
#     declare -p template
#     echo "${template[@]}"
#     echo "${template[@]@Q}"
#
#     shift
#     local -a args=("$@")
#     local item cmd
#     for item in "${args[@]}"; do
#         cmd=$(printf "${template[*]}" "$item")
#         declare -p cmd
#         echo "$cmd"
#         echo $cmd
#         # eval $cmd
#     done
# }

spinner()
{
    (($# == 1)) || return 1
    # local chars='|/-\\'
    local chars='▁▂▃▄▅▆▇█▉▊▋▌▍▎▏ '
    local idx=$(($1 % ${#chars}))
    printf "\e[1K\e[G%s" "${chars:$idx:1}"
}

# ====================

showpath()
{
    # pretty print PATH-like lists or list variables
    # usage: showpath [PATH_OR_VAR...]

    # make a list of parameters, defaulting to just "PATH"
    local args=("${@:-PATH}")

    local value
    for value in "${args[@]}"; do
        if [[ -v $value ]]; then
            # looks like a variable name; let's dereference it
            value=${!value}
        fi

        echo "${value//:/$'\n'}"
    done
} && complete -v showpath

showarray()
{
    # pretty print array variables
    # usage: showarray ARRAYVAR...

    local -n arrayref
    for arrayref in "$@"; do
        local attrib
        attrib=$(attributes "${!arrayref}")

        if [[ ! $attrib =~ [aA] ]]; then
            echo >&2 "[X] not an array: ${!arrayref}"
            continue
        fi

        printf "%s=(\n" "${!arrayref}"
        local key
        for key in "${!arrayref[@]}"; do
            printf "  [%s]=%s\n" "$key" "${arrayref[$key]@Q}"
        done
        printf ")\n"
    done
} && complete -A arrayvar showarray

searchpath()
{
    if [[ $# -eq 0 || $1 == -* ]]; then
        echo "search a PATH-like directory list for files matching patterns"
        echo "usage: ${FUNCNAME[0]} [LIST] GLOB [GLOB...]"
        echo "with a single argument, search \$PATH for the given pattern"
        echo "with two or more arguments, search LIST for each pattern"
        return 1
    fi

    local -a dirlist globs
    if (($# == 1)); then
        from_list dirlist "$PATH"
        globs=("$@")
    else
        from_list dirlist "$1"
        globs=("${@:1}")
    fi

    local dir glob
    for dir in "${dirlist[@]}"; do
        if [[ -z $dir ]]; then
            echo "[.] using current directory for null dir"
            dir=$PWD
        fi
        for glob in "${globs[@]}"; do
            compgen -G "$dir/$glob"
        done
    done
}

searchparents()
{
    local HELP ALL
    while (($# > 0)); do
        local arg=$1 && shift
        case $arg in
            -h | --help) HELP=1 ;;
            -a | --all) ALL=1 ;;
            -*)
                echo >&2 "[X] ${FUNCNAME[0]}: I don't understand \"$arg\""
                HELP=1
                ;;
            *)
                local -a GLOBS+=("$arg")
                ;;
        esac
    done

    if [[ -v HELP ]]; then
        echo "Search from PWD to root directory for files matching patterns"
        echo "usage: ${FUNCNAME[0]} [-a|--all] GLOB [GLOB...]"
        return
    fi

    local retval=1
    local dir=$PWD
    while true; do
        local glob
        for glob in "${GLOBS[@]}"; do
            if compgen -G "$dir/$glob"; then
                retval=0
                [[ -v ALL ]] || break 2
            fi
        done
        local next=${dir%/*}
        [[ $next != "$dir" ]] || break
        dir=$next
    done
    return $retval
}

# stack()
# {
#     local i=0
#     echo "$LINENO $FUNCNAME $BASH_SOURCE"
#     while caller $i; do ((i++)); done
# }
#
# print_stack()
# {
#     stack | while read -r lineno funcname filename; do
#         echo "$funcname ($filename:$lineno)"
#     done
# }
#
# stack()
# {
#     for ((i = ${#BASH_SOURCE[@]} - 1; 1; i--)); do
#         echo "${FUNCNAME[$i]} (${BASH_SOURCE[$i]}:${BASH_LINENO[$i - 1]})"
#     done
# }
#
# stackline()
# {
#     local -a stack
#     get_array stack -- stack
#     join " > " "${stack[@]}"
# }

fatal()
{
    # display an error with an optional message; stacktrace; exit 1
    echo >&2 "[X] ${*:-Fatal Error}"
    stacktrace
    exit 1
}

# shellcheck disable=2120
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

stacktrace()
{
    # print the current call stack
    local context=2 top=0 bottom=0

    local opt OPTARG OPTIND HELP
    while getopts :hc:t:b: opt; do
        case $opt in
            h) HELP=1 ;;
            c) context=$OPTARG ;;
            t) top=$OPTARG ;;
            b) bottom=$OPTARG ;;
            :)
                echo >&2 "[X] ${FUNCNAME[0]}: required argument not found: $OPTARG"
                HELP=1
                ;;
            ?)
                echo >&2 "[X] ${FUNCNAME[0]}: invalid option: $OPTARG"
                HELP=1
                ;;
            *)
                echo >&2 "[X] ${FUNCNAME[0]}: unexpected input"
                local -p opt OPTARG
                HELP=1
                ;;
        esac
    done
    shift $((OPTIND - 1))

    if [[ -v HELP ]]; then
        trim <<< "
            Print a bash function stacktrace
            Usage: ${FUNCNAME[0]} [-h] [-c CONTEXT] [-b BOTTOM] [-t TOP]

            Options:
            -c CONTEXT      print CONTEXT number of lines of context (currently $context)
            -b BOTTOM       trim BOTTOM frames from the bottom of the stack (currently $bottom)
            -t TOP          trim TOP frames from the top of the stack (currently $top)"
        return 1
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
        local filename=${BASH_SOURCE[$idx]}
        local funcname=${FUNCNAME[$idx]}
        local lineno=${BASH_LINENO[$idx - 1]}

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
    done
}

withenv()
(
    # execute a command with `.env` sourced
    local -a envfiles
    get_array envfiles -- searchparents -a .env || true
    local path
    for path in "${envfiles[@]}"; do
        source "$path"
    done
    "$@"
)

with_files()
{
    # run a command & pass `files` as parameters
    # usage: with_files COMMAND [COMMAND_ARGS...] [-- FILES_ARGS...]
    # split our params into command and files_args
    local -a command files
    while (($# > 0)); do
        local arg="$1"
        shift
        case $arg in
            --) break ;;
            *) command+=("$arg") ;;
        esac
    done
    #
    # remaining args, if any, go to `fd`
    get_array files -- fd -t f . "$@" || return
    # check for empty set
    ((${#files[*]} == 0)) && {
        echo >&2 "[X] ${FUNCNAME[0]}: no files"
        return 1
    }
    # handoff
    "${command[@]}" "${files[@]}"
} && complete -c with_files

vimfiles()
{
    # edit all regular files (in $@ or .) with vim
    with_files vim -- "$@"
} && complete -d vimfiles

vimwhich()
{
    local -a targets
    get_array targets -- type -P "$@" || return
    vim "${targets[@]}"
} && complete -c vimwhich

nvfiles()
{
    with_files nvim -- "$@"
} && complete -d nvfiles

nvwhich()
{
    local -a targets
    get_array targets -- type -P "$@" || return
    nvim "${targets[@]}"
} && complete -c nvwhich

mw()
{
    # move a file & cd to that directory
    # mnemonic "move with"
    if [[ $# -lt 2 || $1 == -* ]]; then
        echo "mw: FILE... DIR -> mv FILE... DIR && cd DIR"
        exit 1
    fi
    # the last parameter
    local dest="${*: -1}"
    # everything but the last parameter, as an array
    local files=("${@:1:$#-1}")
    [[ -d $dest ]] || {
        echo "last parameter should be a directory"
        return 1
    }
    mv -t "$dest" "${files[@]}" && cd "$dest" || return
} && complete -f mw

pathmunge()
{
    if (($# == 0 || $# > 2)); then
        echo "Usage: ${FUNCNAME[0]} DIR [after]"
        return 1
    fi

    [[ :$PATH: != *:"$1":* && -d $1 ]] || return 0

    if [[ ${2:-} = after ]]; then
        PATH=$PATH:$1
    else
        PATH=$1:$PATH
    fi
}

pathmungex()
{
    # like pathmunge, but better

    _verbose "$(stackline)"
    _verbose "[.] ${FUNCNAME[0]} $*"

    # EXPORT: whether to export PATHVAR
    # REPLACE: whether to replace matching entries
    # HELP: whether to print help & halt
    local EXPORT REPLACE HELP
    # how to check entries; one of "nocheck", "silent", or "fail"
    local CHECK=silent
    # where to put directories; one of "insert", "before", or "after"
    local WHERE=insert
    # pattern used find entry in PATHVAR where ENTRIES should be inserted
    local MARKER="^/usr/"
    # positional arguments
    local -a POSITIONAL

    while (($# > 0)); do
        local arg=$1 && shift
        case $arg in
            # split --var=value pairs, preserving spaces
            -*=*) set -- "${arg%%=*}" "${arg#*=}" "$@" ;;
            -[^-]?*)
                # split arguments like `-aef` into `-a -e -f`
                arg=${arg#-}
                # shellcheck disable=SC2086  # intentionally splitting token
                set -- ${arg//?/-& } "$@"
                ;;
            -e | --export) EXPORT=1 ;;
            -b | --before) WHERE=before ;;
            -a | --after) WHERE=after ;;
            -f | --fail | --fatal) CHECK=fail ;;
            -n | --no-check | --nocheck) CHECK=nocheck ;;
            -r | --replace) REPLACE=1 ;;
            -h | --help) HELP=1 ;;
            -m | --marker)
                if [[ -v 1 && ! ($1 == -*) ]]; then
                    MARKER="$1"
                else
                    echo >&2 "[X] ${FUNCNAME[0]}: argument required: $arg"
                    HELP=1
                fi
                ;;
            -*)
                echo >&2 "[X] ${FUNCNAME[0]}: I don't understand \"$arg\""
                HELP=1
                ;;
            *) POSITIONAL+=("$arg") ;;
        esac
    done

    if [[ ! -v HELP && ${#POSITIONAL[@]} -lt 2 ]]; then
        echo >&2 "[X] ${FUNCNAME[0]}: Not enough arguments"
        HELP=1
    fi

    if [[ -v HELP ]]; then
        trim <<< "
            Add entries to a PATH-like list variable, for each entry that exists on disk
            and is not already in the list. By default, entries are inserted in order into
            PATHVAR before the first entry that begins with '/usr/'.

            Usage: ${FUNCNAME[0]} [OPTIONS] PATHVAR ENTRIES...

            Parameters:
            PATHVAR     The name of a PATH-like list variable
            ENTRIES     One or more entries to add to PATHVAR

            Options:
            -e | --export       Export PATHVAR
            -a | --after        Append entries to the end of PATHVAR
            -b | --before       Prepend entries to the front of PATHVAR
            -f | --fail         Fail with an error and leave PATHVAR unmodified if any
                                ENTRIES do not exist
            -r | --replace      Remove and re-add existing matching entries
            -n | --no-check     Do not check whether entries exist on disk
            -h | --help         Print this message and halt

            Optional arguments:
            -m | --marker MARKER    A pattern to use to find the entry in PATHVAR where
                                    ENTRIES should be inserted"
        return 1
    fi

    # _debug_var EXPORT HELP CHECK WHERE MARKER POSITIONAL

    local -n PATHVAR="${POSITIONAL[0]}" || return
    local -a ENTRIES=("${POSITIONAL[@]:1}")

    # _debug munging "$WHERE" "${!PATHVAR}"
    # stackline >&2
    # _print_stack
    # stacktrace
    _debug_var ENTRIES "${!PATHVAR}"

    if [[ -v EXPORT ]]; then
        declare -gx "${!PATHVAR}"
    fi

    local ADDITIONS
    local MATCHVAR=:${PATHVAR-}:
    # capture whether or not the original pathvar contains a null entry
    [[ ${PATHVAR-} =~ (^:|::|:$) ]] && local HAS_NULL=1

    local entry
    for entry in "${ENTRIES[@]}"; do
        # entries with embedded colons are not allowed
        if [[ $entry =~ : ]]; then
            echo >&2 "[X] ${FUNCNAME[0]}: invalid entry: \"$entry\""
            return 1
        fi

        # test whether entry is in PATHVAR
        if [[ -z ${PATHVAR-} ]]; then
            # no need to compare against empty list
            true
        elif [[ -n $entry ]]; then
            local matchentry=$entry
            [[ $matchentry == / ]] || matchentry=${matchentry%/}

            if [[ -v REPLACE ]]; then
                # replace `:$entry:` with `:` in MATCHVAR regardless of trailing slashes
                # shellcheck disable=1001
                MATCHVAR=${MATCHVAR//:"$matchentry"?(\/):/:}
            else
                # skip this entry if it already exists in MATCHVAR, regardless of trailing slashes
                [[ ! ${MATCHVAR} =~ :"$matchentry"/?: ]] || continue
            fi
        elif [[ -v HAS_NULL ]]; then
            # special handling for matching or replacing null entries
            if [[ -v REPLACE ]]; then
                MATCHVAR=${MATCHVAR//::/:}
                unset HAS_NULL
            else
                [[ $MATCHVAR != *::* ]] || continue
            fi
        fi

        # check entry
        if [[ $CHECK == nocheck ]]; then
            # explicitly not checking file existance
            true
        elif [[ -z $entry || -e $entry ]]; then
            # null entry or file exists
            true
        elif [[ $CHECK == fail ]]; then
            echo >&2 "[!] ${FUNCNAME[0]}: entry does not exist: $entry"
            return 1
        else
            continue
        fi

        if [[ -v ADDITIONS ]]; then
            # also skip if entry is already in ADDITIONS (which we've already ensured won't have trailing slashes)
            [[ :$ADDITIONS: != *:"$entry":* ]] || continue
            ADDITIONS+=":$entry"
        else
            ADDITIONS="$entry"
        fi
    done

    _debug_var ADDITIONS

    # nothing to add?
    [[ -v ADDITIONS ]] || return 0

    if [[ -v REPLACE ]]; then
        # TL;DR - This is a poor way to implement lists :/

        # /bin:/sbin -> :/bin:/sbin: (0) -> :/bin: (0) -> /bin
        # /bin::/sbin -> :/bin/::/sbin: (1) -> :/bin:: (1) -> /bin:
        # /sbin -> :/sbin: (0) -> : (0) -> ""
        # /sbin: -> :/sbin:: (1) -> :: (1) -> :
        # : -> ::: (1) -> ::: (1) -> :
        # "" -> :: (0) -> :: (0) -> ""
        #
        # /bin: -> :/bin:: (1) -> :/bin: (0) -> /bin
        # : -> ::: (1) -> :: (0) -> ""
        # "" -> :: (0) -> :: (0) -> ""

        # /sbin: -> :/sbin:: (1) -> {{ :: (1) -> : }}
        # "" -> :: (0) -> {{ :: (0) -> "" }}
        # : -> {{ ::: (1) -> :: (0) }} -> ""
        # "" -> {{ :: (0) -> :: (0) }} -> ""

        if [[ -v HAS_NULL && $MATCHVAR == :: ]]; then
            MATCHVAR=:
        else
            MATCHVAR=${MATCHVAR%:}
            MATCHVAR=${MATCHVAR#:}
        fi
        PATHVAR=$MATCHVAR
    fi

    if [[ -z ${PATHVAR-} ]]; then
        PATHVAR=$ADDITIONS
    elif [[ $WHERE = after ]]; then
        PATHVAR=$PATHVAR:$ADDITIONS
    elif [[ $WHERE = before ]]; then
        PATHVAR=$ADDITIONS:$PATHVAR
    else
        # have to split PATHVAR
        local -a PATHARRAY FRONT BACK
        from_list PATHARRAY "$PATHVAR"

        for entry in "${PATHARRAY[@]}"; do
            [[ ! $entry =~ $MARKER ]] || break
            FRONT+=("$entry")
            PATHARRAY=("${PATHARRAY[@]:1}")
            _debug_var PATHARRAY
        done

        BACK=("${PATHARRAY[@]}")

        _debug_var FRONT BACK
        to_list PATHVAR "${FRONT[@]}" "$ADDITIONS" "${BACK[@]}"
    fi
    _debug_var "${!PATHVAR}"
    _verbose "[.] ${!PATHVAR} ([${PATHVAR//:/], [}])"
    hash -r
}

cleanpath()
{
    if [[ $# -gt 1 || $1 == -* ]]; then
        echo "Remove repeated values from PATH, or another PATH-like variable"
        echo "Usage: ${FUNCNAME[0]} [PATHVAR]"
        return 1
    fi

    local -n PATHVAR=${1:-PATH} || return
    declared "${!PATHVAR}" || return

    local -a ENTRIES
    from_list ENTRIES "$PATHVAR" || return

    local CLEAN
    pathmungex CLEAN "${ENTRIES[@]}" || return
    PATHVAR="$CLEAN"
} && complete -v cleanpath

flash_message()
{
    # briefly print a message to the screen
    local HELP message sleep=1
    while (($# > 0)); do
        local arg="$1"
        shift
        case $arg in
            -s | --sleep)
                sleep="$1"
                shift
                ;;
            -h | --help)
                HELP=1
                ;;
            -*)
                echo >&2 "[X] ${FUNCNAME[0]}: Unrecognized option: $arg"
                ;;
            *)
                message+="$arg "
                ;;
        esac
    done

    if [[ -v HELP ]]; then
        trim <<< "
            Briefly print a message to the screen.

            Usage: ${FUNCNAME[0]} [-s|--sleep SLEEP] MESSAGE...
                -s|--sleep: how long to sleep (currently $sleep)"
        return 1
    fi

    tput sc
    figlet "$message"
    sleep "$sleep"
    tput rc
    tput ed
}

# vim()
# {
#     flash_message -s 2 '!!! use nv !!!'
#     nvim "$@"
#     return $?
# }

# don't wanna set pager globally, but do wanna pick one for these
haveexe bat && _pager=bat || _pager=less

jql()
{
    # mnemonic: `jq | less`
    jq -C "${@:-.}" | $_pager
}

yql()
{
    # mnemonic: `yq | less`
    yq -C "${@:-.}" | $_pager
}

pkg-config-vars()
{
    # display all pkg-config variables for a name
    local -a names
    get_array names -- pkg-config-names
    local glob
    for glob in "$@"; do
        local name
        for name in "${names[@]}"; do
            # shellcheck disable=2053  # the globbing is the point
            [[ $name == $glob ]] || continue
            unset vars lines
            local -a vars lines
            get_array vars -- pkg-config "$name" --print-variables
            local var value
            for var in "${vars[@]}"; do
                value=$(pkg-config "$name" --variable "$var")
                lines+=("$var = $value")
            done
            printf "$name: %s\n" "${lines[@]}"
        done
    done
}

pkg-config-names()
{
    pkg-config --list-all | cut -f1 -d" " | sort
}

_complete-pkg-config-names()
{
    # mapfile -t COMPREPLY < <(compgen -W "$(pkg-config-names)" -- "${COMP_WORDS[COMP_CWORD]}")
    get_array COMPREPLY -- compgen -W "$(pkg-config-names)" -- "${COMP_WORDS[COMP_CWORD]}"
}

complete -F _complete-pkg-config-names pkg-config-vars

dush()
{
    # like alias dush=`du -shxc`
    command du -shxc "$@" | sort -h
} && complete -d dush

dfh()
{
    # like alias dfh=`df -hT -t xfs -t ext4`
    df -hT -t xfs -t ext4 "$@" | sort -h -k 4
}

faketty()
{
    # convince a command that it is attached to a tty
    script -qefc "$(printf "%q " "$@")" /dev/null
} && complete -c faketty

mxtime()
{
    # get timestamps for maxar
    (($# > 0)) && local args=(--date "$*")
    date -Iseconds "${args[@]}" | sed 's/+0000/Z/'
}

# wrapper for pstree default arguments
pstree()
{
    (($# == 0)) && set -- -H $$ $$
    command pstree -Uas "$@"
}
