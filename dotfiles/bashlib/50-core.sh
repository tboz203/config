# bashlib core
# shellcheck disable=2016,2059,2120

spinner()
{
    # local chars='|/-\\'
    local chars='▁▂▃▄▅▆▇█▉▊▋▌▍▎▏ '
    if (($# == 0)); then
        declare -g _spinner_idx
        local idx=$((_spinner_idx = (_spinner_idx + 1) % ${#chars}))
    elif (($# == 1)); then
        local idx=$(($1 % ${#chars}))
    else
        return 2
    fi
    printf "\e[1K\e[G%s" "${chars:$idx:1}"
}

showpath()
{
    # pretty print PATH-like lists or list variables
    # usage: showpath [PATH_OR_VAR...]
    local value
    for value in "${@:-PATH}"; do
        if [[ -v $value ]]; then
            # looks like a variable name; let's dereference it
            value=${!value}
        fi

        # echo "${value//:/$'\n'}"
        # IFS=: eval quote '$value'

        local -a array
        from_list array "$value"
        quoted "${array[@]}"
    done
} && complete -v showpath

showarray()
{
    # pretty print array variables
    # usage: showarray ARRAYVAR...

    local name
    for name in "$@"; do
        local attrib
        attrib=$(attributes "$name")

        if [[ $attrib != *[aA]* ]]; then
            echo >&2 "[X] not an array: $name"
            continue
        fi

        local arraycopy
        clone "$name" arraycopy

        printf "%s=(\n" "$name"
        local key value
        for key in "${!arraycopy[@]}"; do
            printf "  [%s]=%s\n" "$key" "$(quoted "${arraycopy[$key]}")"
        done
        echo ")"
    done
} && complete -A arrayvar showarray

searchpath()
{
    # find the first file in a path that matches a glob
    local -a GLOBS=()
    local ALL='' HELP=''
    local LIST=PATH
    eval "$(fixargs "$@")"
    while (($# > 0)); do
        local arg=$1 && shift
        case $arg in
            -a | --all) ALL=1 ;;
            -h | --help) HELP=0 ;;
            -l | --list)
                if [[ -v 1 && $1 != -* ]]; then
                    LIST=$1 && shift
                else
                    echo >&2 "[X] ${FUNCNAME[0]}: argument required: $arg"
                    HELP=2
                fi
                ;;
            -*)
                echo >&2 "[X] ${FUNCNAME[0]}: I don't understand \"$arg\""
                HELP=2
                ;;
            *) GLOBS+=("$arg") ;;
        esac
    done

    if [[ -z $HELP && ${#GLOBS[@]} -lt 1 ]]; then
        echo >&2 "[X] ${FUNCNAME[0]}: Not enough arguments"
        HELP=2
    fi

    if [[ $HELP ]]; then
        dedent <<< "
            Search PATH for a file matching a pattern
            Usage: ${FUNCNAME[0]} [--all] [--list LIST] GLOB [GLOB...]

            Parameters:
            GLOB        A shell pattern to search for in each directory.

            Options:
            -a | --all      Print all matches (default is to print all matches from first
                            successful glob, and then halt).
            -h | --help     Print this message and halt

            Optional Parameters:
            -l | --list LIST    Search through LIST instead of PATH. May be a list of
                                colon-separated directories, or a variable containing such.

            Unless '--all' is specified, each glob is searched in each directory until any
            glob matches. If you wish to exhaustively search for one glob before continuing
            to the next, use '${FUNCNAME[0]} GLOB_1 || ${FUNCNAME[0]} GLOB_2'.

            Returns 2 for invalid arguments, 1 if no matches are found, and 0 otherwise.
            "
        return $HELP
    fi

    if [[ -v $LIST ]]; then
        # if LIST is a variable, dereference it
        LIST=${!LIST}
    fi

    from_list DIRLIST "$LIST"

    local retval=1
    local dir glob
    for dir in "${DIRLIST[@]}"; do
        [[ $dir ]] || dir=$PWD
        for glob in "${GLOBS[@]}"; do
            if compgen -G "$dir/$glob"; then
                retval=0
                [[ $ALL ]] || break 2
            fi
        done
    done
    return $retval
}

searchparents()
{
    local HELP='' ALL=''
    local -a GLOBS=()
    eval "$(fixargs "$@")"
    while (($# > 0)); do
        local arg=$1 && shift
        case $arg in
            -h | --help) HELP=0 ;;
            -a | --all) ALL=1 ;;
            -*)
                echo >&2 "[X] ${FUNCNAME[0]}: I don't understand \"$arg\""
                HELP=2
                ;;
            *)
                GLOBS+=("$arg")
                ;;
        esac
    done

    if [[ $HELP ]]; then
        echo "Search from PWD to root directory for files matching patterns"
        echo "usage: ${FUNCNAME[0]} [-a|--all] GLOB [GLOB...]"
        return $HELP
    fi

    local retval=1
    local dir=$PWD
    while true; do
        local glob
        for glob in "${GLOBS[@]}"; do
            if compgen -G "$dir/$glob"; then
                retval=0
                [[ $ALL ]] || break 2
            fi
        done
        local next=${dir%/*}
        [[ $next != "$dir" ]] || break
        dir=$next
    done
    return $retval
}

fatal()
{
    # display an error with an optional message; stacktrace; exit 1
    echo >&2 "[X] ${*:-Fatal Error}"
    stacktrace
    exit 1
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

# pathmunge()
# {
#     if (($# == 0 || $# > 2)); then
#         echo "Usage: ${FUNCNAME[0]} DIR [after]"
#         return 1
#     fi
#
#     [[ :$PATH: != *:"$1":* && -d $1 ]] || return 0
#
#     if [[ ${2:-} = after ]]; then
#         PATH=$PATH:$1
#     else
#         PATH=$1:$PATH
#     fi
# }

pathmungex()
{
    # like pathmunge, but better

    _verbose _log "$* # called at $(called-at 1)"

    local EXPORT='' REPLACE='' HELP=''
    local CHECK=silent
    local WHERE=insert
    local MARKER="^/usr/"
    local -a POSITIONAL=()

    eval "$(fixargs "$@")"
    while (($# > 0)); do
        local arg=$1 && shift
        case $arg in
            -e | --export) EXPORT=1 ;;
            -b | --before) WHERE=before ;;
            -a | --after) WHERE=after ;;
            -f | --fail | --fatal) CHECK=fail ;;
            -n | --no-check | --nocheck) CHECK=nocheck ;;
            -r | --replace) REPLACE=1 ;;
            -h | --help) HELP=0 ;;
            -m | --marker)
                if [[ -v 1 && ! ($1 == -*) ]]; then
                    MARKER="$1" && shift
                else
                    echo >&2 "[X] ${FUNCNAME[0]}: argument required: $arg"
                    HELP=2
                fi
                ;;
            -*)
                echo >&2 "[X] ${FUNCNAME[0]}: I don't understand \"$arg\""
                HELP=2
                ;;
            *) POSITIONAL+=("$arg") ;;
        esac
    done

    if [[ -z $HELP && ${#POSITIONAL[@]} -lt 2 ]]; then
        echo >&2 "[X] ${FUNCNAME[0]}: Not enough arguments"
        HELP=2
    fi

    if [[ $HELP ]]; then
        dedent <<< "
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

            Optional Parameters:
            -m | --marker MARKER    A pattern to use to find the entry in PATHVAR where
                                    ENTRIES should be inserted"
        return $HELP
    fi

    local PATHVAR="${POSITIONAL[0]}"
    local -a ENTRIES=("${POSITIONAL[@]:1}")

    if [[ $EXPORT ]]; then
        declare -gx "$PATHVAR"
    fi

    # In PATHVAR, `` represents an empty list, and `:` represents a list with a
    # single null element. In PATHLIST and ADDITIONS, `:` represents an empty
    # list, and `::` represents a list with a single null element.

    local PATHLIST
    case ${!PATHVAR-} in
        "") PATHLIST=: ;;
        :) PATHLIST=:: ;;
        *) PATHLIST=:${!PATHVAR}: ;;
    esac
    local ADDITIONS=:

    if [[ $REPLACE ]]; then
        # replace runs of three or more colons (representing two or more adjacent
        # null entries) with a pair of colons (representing a single null entry).
        # This allows us to correctly remove null entries
        PATHLIST=${PATHLIST//::+(:)/::}
    fi

    _debug inspect_var EXPORT HELP CHECK WHERE MARKER POSITIONAL PATHVAR "$PATHVAR" PATHLIST ENTRIES ADDITIONS

    local entry
    for entry in "${ENTRIES[@]}"; do
        # entries with embedded colons are not allowed
        if [[ $entry == *:* ]]; then
            echo >&2 "[X] ${FUNCNAME[0]}: invalid entry: \"$entry\""
            return 1
        fi

        # if the list is not empty, check for our entry
        if [[ $PATHLIST != : ]]; then
            # either the entry is `/`, or we should strip a trailing slash
            local match=$entry
            [[ $match == / ]] || match=${match%/}
            # either the entry is null, or we should match list values with trailing slashes
            local suffix=
            [[ -z $match ]] || suffix="?(/)"

            if [[ $REPLACE ]]; then
                # replace `:$entry:` with `:`
                PATHLIST=${PATHLIST//:"$match"$suffix:/:}
            else
                # skip this entry if it already exists in the list
                [[ ${PATHLIST} != *:"$match"$suffix:* ]] || continue
            fi
        fi

        # do any entry checking
        if [[ $CHECK == nocheck ]]; then
            # explicitly not checking file existance
            true
        elif [[ -z $entry || -e $entry ]]; then
            # null entry or file exists
            # strip a trailing slash (unless entry is `/`)
            [[ $entry == / ]] || entry=${entry%/}
        elif [[ $CHECK == fail ]]; then
            echo >&2 "[!] ${FUNCNAME[0]}: entry does not exist: $entry"
            return 1
        else
            continue
        fi

        # also skip if entry is already in ADDITIONS (which we've already ensured won't have trailing slashes)
        [[ $ADDITIONS != *:"$entry":* ]] || continue
        ADDITIONS+="$entry:"
    done

    # nothing to add?
    [[ $ADDITIONS != : ]] || return 0

    if [[ $WHERE == insert ]]; then
        # have to split PATHLIST
        local -a PATHARRAY FRONT BACK
        PATHLIST=${PATHLIST%:}
        PATHLIST=${PATHLIST#:}
        from_list PATHARRAY "$PATHLIST"

        for entry in "${PATHARRAY[@]}"; do
            [[ ! $entry =~ $MARKER ]] || break
            FRONT+=("$entry")
            PATHARRAY=("${PATHARRAY[@]:1}")
        done

        BACK=("${PATHARRAY[@]}")

        ADDITIONS=${ADDITIONS%:}
        ADDITIONS=${ADDITIONS#:}

        to_list "$PATHVAR" "${FRONT[@]}" "$ADDITIONS" "${BACK[@]}"
    else
        if [[ $WHERE == before ]]; then
            PATHLIST=${ADDITIONS%:}${PATHLIST}
        elif [[ $WHERE == after ]]; then
            PATHLIST=${PATHLIST%:}${ADDITIONS}
        else
            echo >&2 "[X] ${FUNCNAME[0]}: invalid WHERE ($WHERE)"
            return 1
        fi

        case $PATHLIST in
            # PATHLIST is empty
            :) eval "$PATHVAR=" ;;
            # PATHLIST is a single null entry
            ::) eval "$PATHVAR=:" ;;
            # PATHLIST has a leading & a trailing separator
            *)
                PATHLIST=${PATHLIST%:}
                PATHLIST=${PATHLIST#:}
                eval "$PATHVAR=\"$PATHLIST\""
                ;;
        esac
    fi

    # if [[ -z ${!PATHVAR-} ]]; then
    #     eval "$PATHVAR=\"$ADDITIONS\""
    # elif [[ $WHERE = after ]]; then
    #     eval "$PATHVAR=\"${!PATHVAR}:$ADDITIONS\""
    # elif [[ $WHERE = before ]]; then
    #     eval "$PATHVAR=\"$ADDITIONS:${!PATHVAR}\""
    # else
    #     # have to split PATHVAR
    #     local -a PATHARRAY FRONT BACK
    #     from_list PATHARRAY "${!PATHVAR}"
    #
    #     for entry in "${PATHARRAY[@]}"; do
    #         [[ ! $entry =~ $MARKER ]] || break
    #         FRONT+=("$entry")
    #         PATHARRAY=("${PATHARRAY[@]:1}")
    #     done
    #
    #     BACK=("${PATHARRAY[@]}")
    #
    #     to_list "$PATHVAR" "${FRONT[@]}" "$ADDITIONS" "${BACK[@]}"
    # fi

    _debug inspect_var PATHLIST ADDITIONS FRONT BACK
    _verbose _log "set $PATHVAR to ([${!PATHVAR//:/], [}])"
    hash -r
}

cleanpath()
{
    if [[ $# -gt 1 || ${1-} == -* ]]; then
        echo "Remove repeated values from PATH, or another PATH-like variable"
        echo "Usage: ${FUNCNAME[0]} [PATHVAR]"
        return 1
    fi

    local PATHVAR=${1:-PATH}
    declared "$PATHVAR" || return

    local -a ENTRIES
    from_list ENTRIES "${!PATHVAR}" || return

    local CLEAN
    pathmungex CLEAN "${ENTRIES[@]}" || return
    eval "$PATHVAR=\"$CLEAN\""
} && complete -v cleanpath

flash_message()
{
    # briefly print a message to the screen
    local HELP='' message='' sleep=1
    eval "$(fixargs "$@")"
    while (($# > 0)); do
        local arg="$1" && shift
        case $arg in
            -s | --sleep) sleep="${1?}" && shift ;;
            -h | --help) HELP=0 ;;
            -*)
                echo >&2 "[X] ${FUNCNAME[0]}: Unrecognized option: $arg"
                HELP=2
                ;;
            *) message+="$arg " ;;
        esac
    done

    if [[ $HELP ]]; then
        dedent <<< "
            Briefly print a message to the screen.

            Usage: ${FUNCNAME[0]} [-s|--sleep SLEEP] MESSAGE...
                -s|--sleep: how long to sleep (currently $sleep)"
        return $HELP
    fi

    tput sc
    figlet "$message"
    sleep "$sleep"
    tput rc
    tput ed
}

jql()
{
    # mnemonic: `jq | less`
    # shellcheck disable=2155
    local pager=$(type -P bat || type -P less)
    jq -C "${@:-.}" | "$pager"
}

yql()
{
    # mnemonic: `yq | less`
    # shellcheck disable=2155
    local pager=$(type -P bat || type -P less)
    yq -C "${@:-.}" | "$pager"
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
            local -a vars
            get_array vars -- pkg-config "$name" --print-variables
            local -a lines=()
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
    local -a args
    (($# > 0)) && args=(--date "$*")
    date -Iseconds "${args[@]}" | sed 's/+0000/Z/'
}

pstree()
{
    # wrapper for pstree default arguments
    (($# == 0)) && set -- -H $$ $$
    command pstree -Uas "$@"
}

# loud()
# {
#     eval "$(fixargs "$@")"
#     while (($# > 0)); do
#         local arg="$1" && shift
#         case $arg in
#             -s | --sleep) sleep="$1" && shift ;;
#             -h | --help) HELP=1 ;;
#             -*) echo >&2 "[X] ${FUNCNAME[0]}: Unrecognized option: $arg" ;;
#             *) message+="$arg " ;;
#         esac
#     done
# }
