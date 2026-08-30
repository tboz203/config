# bashlib core
# shellcheck disable=2016,2034,2059,2120

function spinner {
    # local chars='|/-\\'
    local chars='▁▂▃▄▅▆▇█▉▊▋▌▍▎▏ '
    if (($# == 0)); then
        declare -g _spinner_idx
        [[ ${_spinner_idx-} ]] || _spinner_idx=0
        local idx=$((_spinner_idx = (_spinner_idx + 1) % ${#chars}))
    elif (($# == 1)); then
        local idx=$(($1 % ${#chars}))
    else
        return 2
    fi
    printf "\e[1K\e[G%s" "${chars:idx:1}"
}

function setpath {
    local -a POSITIONAL
    local EXPORT RETURN HELP USAGE
    fixargs
    while (($#)); do
        local arg=$1 && shift
        case $arg in
            -h | --help) HELP=1 ;;
            -e | --export) EXPORT=1 ;;
            -r | --return) RETURN=1 ;;
            -*)
                _err "Unknown option: \"$arg\""
                USAGE=1
                ;;
            *) POSITIONAL+=("$arg") ;;
        esac
    done

    set -- "${POSITIONAL[@]}"

    USAGE_TEXT="${FUNCNAME[0]} [-e|--export] [-r|--return] VAR PATH"

    if [[ ${HELP-} ]]; then
        trim <<< "
                Set a variable to a path if that path exists
                Usage: $USAGE_TEXT

                Parameters:
                VAR     A variable name
                PATH    A file or directory path

                Options:
                -e | --export   Export the given variable
                -r | --return   Return success or failure
                -h | --help     Print this message and halt
                "
        return 0
    fi

    if (($# != 2)); then
        _err "Wrong number of arguments"
        USAGE=1
    fi

    if [[ ${USAGE-} ]]; then
        _err "Usage: ${FUNCNAME[0]} [OPTIONS] VAR PATH"
        return 2
    fi

    local -n name=$1 && shift
    local path=$1 && shift

    if [[ -e $path ]]; then
        declare -g "${!name}"
        name=$path
        if [[ ${EXPORT-} ]]; then
            declare -xg "${!name}"
        fi
    elif [[ ${RETURN-} ]]; then
        return 1
    fi
} && alias setpath='withflags +vx -- \setpath '

function sourcepath {
    if [[ $# -ne 1 || ${1-} == -* ]]; then
        echo "Source a script if it exists"
        echo "Usage: ${FUNCNAME[0]} PATH"
        return 2
    elif [[ -e $1 ]]; then
        source "$1"
    fi
} && complete -f sourcepath

function showpath {
    # pretty print PATH-like lists or list variables
    # usage: showpath [PATH_OR_VAR...]
    local value
    for value in "${@:-PATH}"; do
        if [[ -v $value ]]; then
            # looks like a variable name; let's dereference it
            value=${!value}
        fi

        local -a patharray
        from_list patharray "$value"
        printeach "%s\n" "${patharray[@]}"
    done
} && complete -v showpath

function showarray {
    # pretty print array variables
    # usage: showarray ARRAYVAR...

    local -n arrayref
    for arrayref in "$@"; do
        if [[ ${arrayref@a} != *[aA]* ]]; then
            _err "Not an array: ${!arrayref}"
            continue
        fi

        println "${!arrayref}=("
        local key
        for key in "${!arrayref[@]}"; do
            printf "  [%s]=%s\n" "$key" "${arrayref[$key]@Q}"
        done
        println ")"
    done
} && complete -A arrayvar showarray

function searchpath {
    # find the first file in a path that matches a glob
    local -a GLOBS
    local ALL HELP USAGE
    local LIST=PATH
    fixargs
    while (($#)); do
        local arg=$1 && shift
        case $arg in
            -a | --all) ALL=1 ;;
            -h | --help) HELP=1 ;;
            -l | --list)
                if [[ ${1-} && $1 != -* ]]; then
                    LIST=$1 && shift
                else
                    _err "Argument required: \"$arg\""
                    USAGE=1
                fi
                ;;
            -*) _err "Unrecognized option: \"$arg\"" && USAGE=1 ;;
            *) GLOBS+=("$arg") ;;
        esac
    done

    if [[ ${HELP-} ]]; then
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
        return 0
    fi

    if [[ ${#GLOBS[@]} -lt 1 ]]; then
        _err "Not enough arguments"
        USAGE=1
    fi

    if [[ ${USAGE-} ]]; then
        _err "Usage: $USAGE_TEXT"
        return 2
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
                [[ ${ALL-} ]] || break 2
            fi
        done
    done
    return $retval
}

function searchparents {
    local HELP ALL
    local -a GLOBS
    fixargs
    while (($#)); do
        local arg=$1 && shift
        case $arg in
            -h | --help) HELP=0 ;;
            -a | --all) ALL=1 ;;
            -*)
                _err "Unrecognized option: \"$arg\""
                HELP=2
                ;;
            *)
                GLOBS+=("$arg")
                ;;
        esac
    done

    if [[ ${HELP-} ]]; then
        _err "Search from PWD to root directory for files matching patterns"
        _err "Usage: ${FUNCNAME[0]} [-a|--all] GLOB..."
        return $HELP
    fi

    local retval=1
    local dir=$PWD
    while true; do
        local glob
        for glob in "${GLOBS[@]}"; do
            if compgen -G "$dir/$glob"; then
                retval=0
                [[ ${ALL-} ]] || break 2
            fi
        done
        local next=${dir%/*}
        [[ $next != "$dir" ]] || break
        dir=$next
    done
    return $retval
}

function with_files {
    # run a command & pass `files` as parameters
    # usage: with_files COMMAND [COMMAND_ARGS...] [-- FILES_ARGS...]
    # split our params into command and files_args
    local -a command files
    while (($#)); do
        local arg="$1" && shift
        case $arg in
            --) break ;;
            *) command+=("$arg") ;;
        esac
    done

    # remaining args, if any, go to `fd`
    get_array files fd -t f . "$@" || return

    # check for empty set
    ((${#files[*]} != 0)) || throw "no files"

    # handoff
    "${command[@]}" "${files[@]}"
} && complete -c with_files

function with_env {
    # execute a command after sourcing a `.env` file
    local -a envfiles
    get_array envfiles searchparents -a .env || true
    local path
    for path in "${envfiles[@]}"; do
        source "$path"
    done
    "$@"
} && complete -c with_env

function pathmungex {
    # like pathmunge, but better

    _if_verbose _log "$* # called at $(called-at 1)"

    local HELP USAGE
    local CHECK=silent
    local WHERE=insert
    local MARKER="^/usr/|^/c/windows/"
    local -a POSITIONAL

    fixargs
    while (($#)); do
        local arg=$1 && shift
        case $arg in
            -e | --export) local EXPORT=1 ;;
            -E | --exists) local EXISTS=1 ;;
            -b | --before) WHERE=before ;;
            -a | --after) WHERE=after ;;
            -f | --fail | --fatal) CHECK=fail ;;
            -n | --no-check | --nocheck) CHECK=nocheck ;;
            -r | --replace) local REPLACE=1 ;;
            -R | --replace-matching) local REPLACE=1 MATCHING=1 ;;
            -d | --delete) local DELETE=1 ;;
            -D | --delete-matching) local DELETE=1 MATCHING=1 ;;
            -h | --help) HELP=1 ;;
            -m | --marker)
                if [[ -v 1 && $1 != -* ]]; then
                    MARKER=$1 && shift
                else
                    _err "Argument required: \"$arg\""
                    USAGE=1
                fi
                ;;
            -*)
                _err "Unrecognized option: \"$arg\""
                USAGE=1
                ;;
            *) POSITIONAL+=("$arg") ;;
        esac
    done

    set -- "${POSITIONAL[@]}"

    local USAGE_TEXT="${FUNCNAME[0]} [OPTIONS] PATHVAR ENTRIES..."

    if [[ ${HELP-} ]]; then
        dedent <<< "
                Add entries to a PATH-like list variable, for each entry that exists on disk
                and is not already in the list. By default, entries are inserted in order into
                PATHVAR before the first entry that begins with '/usr/'.

                Usage: $USAGE_TEXT

                Parameters:
                PATHVAR     The name of a PATH-like list variable
                ENTRIES     One or more entries to add to PATHVAR

                Options:
                -e | --export       Export PATHVAR
                -E | --exists       Only update PATHVAR if it already exists
                -a | --after        Append entries to the end of PATHVAR
                -b | --before       Prepend entries to the front of PATHVAR
                -f | --fail         Fail with an error and leave PATHVAR unmodified if any
                                    ENTRIES do not exist
                -r | --replace      Remove and re-add existing matching entries
                -d | --delete       Remove matching entries
                -D | --delete-matching
                                    Remove matching entries, respecting wildcards
                -n | --no-check     Do not check whether entries exist on disk
                -h | --help         Print this message and halt

                Optional Parameters:
                -m | --marker MARKER    A pattern to use to find the entry in PATHVAR where
                                        ENTRIES should be inserted"
        return 0
    fi

    if (($# == 0)); then
        _err "Not enough arguments"
        USAGE=1
    fi

    if (($# == 1)); then
        set -- PATH "$@"
    fi

    if [[ ${USAGE-} ]]; then
        _err "Usage: $USAGE_TEXT"
        return 2
    fi

    local -n PATHVAR=$1 && shift
    local -a ENTRIES=("$@")

    if [[ ${EXISTS-} && ! -v PATHVAR ]]; then
        _if_verbose _log "PATHVAR ${!PATHVAR} does not exist; returning"
        return 0
    fi

    if [[ ${EXPORT-} ]]; then
        declare -gx PATHVAR
    fi

    # if the file system is not case sensitive, make everything lowercase
    if [[ ${PWD,,} -ef ${PWD^^} ]]; then
        PATHVAR=${PATHVAR,,}
        ENTRIES=("${ENTRIES[@],,}")
        MARKER=${MARKER,,}
    fi

    # In PATHVAR, `` represents an empty list, and `:` represents a list with a
    # single null element. In PATHLIST and ADDITIONS, `:` represents an empty
    # list, and `::` represents a list with a single null element. otherwise,
    # PATHLIST == :PATHVAR:

    local PATHLIST ADDITIONS=:
    wraplist PATHLIST "$PATHVAR"

    _if_debug inspect_var EXPORT CHECK WHERE MARKER POSITIONAL PATHVAR PATHLIST ENTRIES

    if [[ ${MATCHING-} ]]; then
        local ENTRYGLOB
        ENTRYGLOB=$(join '|' "${ENTRIES[@]}")
        ENTRYGLOB="@($ENTRYGLOB)?(/)"
        local -a PATHARRAY
        IFS=: read -ra PATHARRAY <<< "$PATHVAR"
        PATHLIST=:
        local pathitem
        for pathitem in "${PATHARRAY[@]}"; do
            # shellcheck disable=2053  # the glob matching is intentional
            if [[ $pathitem = $ENTRYGLOB ]]; then
                ADDITIONS+="$pathitem:"
            else
                PATHLIST+="$pathitem:"
            fi
        done
    else
        local entry
        for entry in "${ENTRIES[@]}"; do
            # either attempt cygwin path translation, or noop
            [[ $entry == *\\* ]] && entry=$(cygpath "$entry")

            # entries with embedded colons are not allowed
            [[ $entry != *:* ]] || throw "invalid entry: \"$entry\""

            # if the list is not empty, check for our entry
            if [[ $PATHLIST != : ]]; then
                # either the entry is `/`, or we should strip a trailing slash
                local match=$entry
                [[ $match == / ]] || match=${match%/}
                # either the entry is null, or we should match list values with trailing slashes
                local suffix=
                [[ -z $match ]] || suffix="?(/)"

                if [[ ${REPLACE-} || ${DELETE-} ]]; then
                    # replace `:$entry:` with `:`
                    PATHLIST=${PATHLIST//:"$match"$suffix:/:}
                else
                    # skip this entry if it already exists in the list
                    [[ ${PATHLIST} != *:"$match"$suffix:* ]] || continue
                fi
            fi

            if [[ ${DELETE-} ]]; then
                # no need to check entry or track additions
                continue
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
                throw "entry does not exist: $entry"
            else
                continue
            fi

            # also skip if entry is already in ADDITIONS (which we've already ensured won't have trailing slashes)
            [[ $ADDITIONS != *:"$entry":* ]] || continue
            ADDITIONS+="$entry:"
        done
    fi

    if [[ ${DELETE-} ]]; then
        unwraplist PATHVAR "$PATHLIST"
    elif [[ $ADDITIONS == : ]]; then
        _if_verbose _log "Nothing to add"
    else
        case $WHERE in
            before) unwraplist PATHVAR "${ADDITIONS%:}${PATHLIST}" ;;
            after) unwraplist PATHVAR "${PATHLIST%:}${ADDITIONS}" ;;
            insert)
                # have to split PATHLIST to insert our additions

                local -a PATHARRAY FRONT BACK
                ADDITIONS=${ADDITIONS%:} && ADDITIONS=${ADDITIONS#:}
                PATHLIST=${PATHLIST%:} && PATHLIST=${PATHLIST#:}
                from_list PATHARRAY "$PATHLIST"

                # find the index in PATHARRAY of the first element that matches our marker
                local idx
                for ((idx = 0; idx < ${#PATHARRAY[@]}; idx++)); do
                    [[ ${PATHARRAY[idx]} =~ $MARKER ]] && break || true
                done

                # split PATHARRAY before that index
                FRONT=("${PATHARRAY[@]::idx}")
                BACK=("${PATHARRAY[@]:idx}")

                # recombine our arrays, with our additions list between them
                to_list PATHVAR "${FRONT[@]}" "$ADDITIONS" "${BACK[@]}"
                ;;
            *) throw "invalid WHERE ($WHERE)" ;;
        esac
    fi

    _if_debug inspect_var PATHLIST ADDITIONS FRONT BACK
    _if_verbose _log "set $PATHVAR to ([${!PATHVAR//:/], [}])"
    hash -r
} && alias pathmungex='withflags +vx -- \pathmungex '

function cleanpath {
    if [[ $# -gt 1 || ${1-} == -* ]]; then
        echo "Remove repeated values from PATH, or another PATH-like variable"
        echo "Usage: ${FUNCNAME[0]} [PATHVAR]"
        return 1
    fi

    local -n PATHVAR=${1:-PATH}

    local -a ENTRIES
    from_list ENTRIES PATHVAR || return

    local CLEAN
    pathmungex CLEAN "${ENTRIES[@]}" || return
    PATHVAR=$CLEAN
} && complete -v cleanpath

function flash_message {
    # briefly print a message to the screen
    local HELP message sleep=1
    fixargs
    while (($#)); do
        local arg="$1" && shift
        case $arg in
            -s | --sleep) sleep="${1:?$arg: argument required}" && shift ;;
            -h | --help) HELP=0 ;;
            -*)
                _err "Unrecognized option: \"$arg\""
                HELP=2
                ;;
            *) message+="$arg " ;;
        esac
    done

    if [[ ${HELP-} ]]; then
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

function filetype {
    throw "not implemented"
    (($# >= 1)) || throw "Not enough arguments"
    local cmd
    for cmd in "$@"; do
        case $(type -t "$cmd") in
            alias) ;;
            keyword) ;;
            function) ;;
            builtin) ;;
            file) ;;
            *) ;;
        esac
    done
} && complete -c filetype

if type -P cygpath &> /dev/null; then
    # function _cygpath {
    #     cygpath "$@"
    # }

    function cygvar {
        local help arg
        local -a names options
        for arg in "$@"; do
            shift
            case $arg in
                --) names+=("$@") && break ;;
                -h | --help) help=1 ;;
                -*) options+=("$arg") ;;
                *) names+=("$arg") ;;
            esac
        done

        if [[ ${help-} ]]; then
            _err "Convert named environment variables using cygpath"
            _err "Usage: ${FUNCNAME[0]} [OPTION...] NAME [NAME...]"
            return 2
        fi

        local -n var
        for var in "${names[@]}"; do
            if [[ -v ${!var} ]]; then
                var=$(cygpath "${options[@]}" "$var") || throw "Failed to update var: ${!var}"
            else
                _warn "Variable not set: ${!var}"
            fi
        done
    }
else
    function _cygpath {
        echo "$@"
    }

    function cygvar {
        true
    }
fi
