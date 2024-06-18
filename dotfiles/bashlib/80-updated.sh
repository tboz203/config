# bashlib functions using modern features

((BASH_VERSINFO[0] >= 5)) || return 0

from_list()
{
    if [[ $# -ne 2 || $1 == -* ]]; then
        echo "Convert a colon-separated list to a Bash array variable"
        echo "Usage: ${FUNCNAME[0]} <ARRAY_NAME> <LIST>"
        return 2
    fi

    local -n arrayref=$1 || return 2
    local list=$2

    declared "${!arrayref}" || declare -ga "${!arrayref}" || return 1

    if [[ -z $list ]]; then
        arrayref=()
    elif [[ $list == : ]]; then
        arrayref=('')
    else
        # read into arrayref, splitting on `:`
        # (seems to use terminator semantics, so add an extra final separator)
        IFS=: read -r -d '' -a "${!arrayref}" < <(printf "%s" "${list}:") || true
    fi
}

to_list()
{
    if [[ $# -lt 1 || $1 == -* ]]; then
        echo "Create a colon-separated list from zero or more elements"
        echo "Usage: ${FUNCNAME[0]} <LIST_NAME> [ELEM...]"
        return 2
    fi

    local -n listref=$1 && shift
    declared "${!listref}" || declare -g "${!listref}"

    local IFS=:
    listref="$*"
}

showarray()
{
    # pretty print array variables
    # usage: showarray ARRAYVAR...

    local -n arrayref
    for arrayref in "$@"; do
        local attrib
        attrib=$(attributes "${!arrayref}")

        if [[ $attrib != *[aA]* ]]; then
            echo >&2 "[X] not an array: $arrayref"
            continue
        fi

        printf "%s=(\n" "${!arrayref}"
        local key
        for key in "${![@]}"; do
            printf "  [%s]=%s\n" "$key" "${arrayref[$key]@Q}"
        done
        echo ")"
    done
}

pathmungex()
{
    # like pathmunge, but better

    # local state=${-//[^xT]}
    # trap 'set +xT -$state ; trap - RETURN' RETURN
    # set -x +T

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

    local -n PATHVAR=${POSITIONAL[0]}
    local -a ENTRIES=("${POSITIONAL[@]:1}")

    if [[ $EXPORT ]]; then
        declare -gx "${!PATHVAR}"
    fi

    # In PATHVAR, `` represents an empty list, and `:` represents a list with a
    # single null element. In PATHLIST and ADDITIONS, `:` represents an empty
    # list, and `::` represents a list with a single null element.

    local PATHLIST
    case ${PATHVAR-} in
        "") PATHLIST=: ;;
        :) PATHLIST=:: ;;
        *) PATHLIST=:$PATHVAR: ;;
    esac
    local ADDITIONS=:

    # if [[ $REPLACE ]]; then
    #     # replace runs of three or more colons (representing two or more adjacent
    #     # null entries) with a pair of colons (representing a single null entry).
    #     # This allows us to correctly remove null entries
    #     PATHLIST=${PATHLIST//::+(:)/::}
    # fi

    _debug inspect_var EXPORT HELP CHECK WHERE MARKER POSITIONAL PATHVAR "${!PATHVAR}" ENTRIES

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
                [[ $PATHLIST != *:"$match"$suffix:* ]] || continue
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

    _debug inspect_var PATHLIST ADDITIONS

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

        to_list "${!PATHVAR}" "${FRONT[@]}" "$ADDITIONS" "${BACK[@]}"
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
            :) PATHVAR="" ;;
            # PATHLIST is a single null entry
            ::) PATHVAR=: ;;
            # PATHLIST has a leading & a trailing separator
            *)
                PATHLIST=${PATHLIST%:}
                PATHLIST=${PATHLIST#:}
                PATHVAR=$PATHLIST
                ;;
        esac
    fi

    _debug inspect_var FRONT BACK
    _verbose _log "set ${!PATHVAR} to ([${PATHVAR//:/], [}])"
    hash -r
}

cleanpath()
{
    if [[ $# -gt 1 || ${1-} == -* ]]; then
        echo "Remove repeated values from PATH, or another PATH-like variable"
        echo "Usage: ${FUNCNAME[0]} [PATHVAR]"
        return 1
    fi

    local -n PATHVAR=${1:-PATH} || return 2
    declared "${!PATHVAR}" || return

    local -a ENTRIES
    from_list ENTRIES "$PATHVAR" || return

    local CLEAN=
    pathmungex CLEAN "${ENTRIES[@]}" || return
    PATHVAR=$CLEAN
}

