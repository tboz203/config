# .bash_functions
# vim: filetype=sh tabstop=4 shiftwidth=0 softtabstop=-1 expandtab
# shellcheck disable=SC2016

get_array()
{
    : '`readarray` with error handling'
    : 'usage: get_array [READARRAY_ARGS...] ARRAY -- COMMAND...'
    declare -a mapargs
    while [[ $# -gt 0 ]]; do
        declare arg=$1
        shift
        case $arg in
            --) break ;;
            *) mapargs+=("$arg") ;;
        esac
    done
    if [[ $# -eq 0 ]]; then
        echo >&2 "[X] get_array: no command given"
        return 1
    elif [[ ${#mapargs[*]} -eq 0 ]]; then
        # technically you could call like `get_array -d : -- echo $PATH` and
        # pass this check, but if you've gotten that far, i'll assume you know
        # what you're doing
        echo >&2 "[X] get_array: no array given"
        return 1
    fi

    # execute the command
    declare fulltext
    fulltext=$("$@") || {
        declare err=$?
        echo >&2 -n "$fulltext"
        return $err
    }

    # map the array
    readarray -t "${mapargs[@]}" <<< "$fulltext"
}

with_files()
{
    : 'run a command & pass `files` as parameters'
    : 'usage: with_files COMMAND [COMMAND_ARGS...] [-- FILES_ARGS...]'
    # split our params into command and files_args
    declare -a command files
    while [[ $# -gt 0 ]]; do
        declare arg="$1"
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
    [[ ${#files[*]} -eq 0 ]] && {
        echo >&2 "[X] no files"
        return 1
    }
    # handoff
    "${command[@]}" "${files[@]}"
}

vimfiles()
{
    : 'edit all regular files (in $@ or .) with vim'
    with_files vim -- "$@"
}
# if we have `_filedir` from bash completion, use it
declare -F _filedir &> /dev/null && complete -F _filedir -d vimfiles

vimwhich()
{
    declare -a targets
    get_array targets -- type -P "$@" || return
    vim "${targets[@]}"
}
complete -c vimwhich

nvfiles()
{
    with_files nvim -- "$@"
}
# if we have `_filedir` from bash completion, use it
declare -F _filedir &> /dev/null && complete -F _filedir -d nvfiles

nvwhich()
{
    declare -a targets
    get_array targets -- type -P "$@" || return
    nvim "${targets[@]}"
}
complete -c nvwhich

mw()
{
    : 'move a file & cd to that directory'
    # mnemonic "move with"
    if [[ $# -lt 2 || " $* " =~ " -h " || " $* " =~ " --help " ]]; then
        echo "mw: FILE... DIR -> mv FILE... DIR && cd DIR"
        exit 1
    fi
    # the last parameter
    declare dest="${*: -1}"
    # everything but the last parameter, as an array
    declare files=("${@:1:$#-1}")
    [[ -d $dest ]] || {
        echo "last parameter should be a directory"
        return 1
    }
    mv -t "$dest" "${files[@]}" && cd "$dest" || return
}
# if we have `_filedir` from bash completion, use it
declare -F _filedir &> /dev/null && complete -F _filedir mw

repeat()
{
    : 'usage: repeat TEXT COUNT'
    : 'does something a bit like `TEXT * COUNT`'
    declare text="$1"
    declare count="$2"
    printf "${text}%.0s" $(seq 1 "$count")
}

pathmunge()
{
    if [[ $# -lt 1 || $# -gt 2 ]]; then
        echo "[X] pathmunge: bad arguments:$*"
        echo "Usage: pathmunge DIR [after]"
        return 1
    fi

    [[ :$PATH: != *:$1:* && -d $1 ]] || return

    if [[ ${2:-} = after ]]; then
        PATH=$PATH:$1
    else
        PATH=$1:$PATH
    fi
}

pathmungex()
{
    : 'like pathmunge, but better'

    # PATHVAR: indirect reference to a global PATH-like variable
    # (not a `declare -n` reference; all indirection is explicit)
    # EXPORT: whether to export PATHVAR
    # HELP: whether to print help & halt
    declare PATHVAR EXPORT HELP
    # CHECK: how to check entries; one of "nocheck", "silent", or "fail"
    declare CHECK=silent
    # WHERE: where to put directories; one of "insert", "before", or "after"
    declare WHERE=insert
    # MARKER: pattern used find entry in PATHVAR where ENTRIES should be inserted
    declare MARKER="^/usr/"
    # ENTRIES: a list of dirs to be added to PATHVAR
    declare -a ENTRIES

    while [[ $# -gt 0 ]]; do
        declare arg="$1"
        shift
        case $arg in
            # split --var=value pairs, preserving spaces
            -*=*) set -- "${arg%%=*}" "${arg#*=}" "$@" ;;
            -[^-]?*)
                # split arguments like `-aef` into `-a -e -f`
                # shellcheck disable=SC2046  # intentionally splitting token
                set -- $(sed -e 's/^-//' -e 's/./-\0 /g' <<< "$arg") "$@"
                ;;
            -e | --export) EXPORT=1 ;;
            -b | --before) WHERE=before ;;
            -a | --after) WHERE=after ;;
            -f | --fail | --fatal) CHECK=fail ;;
            -n | --no-check | --nocheck) CHECK=nocheck ;;
            -h | --help) HELP=1 ;;
            -m | --marker)
                if [[ -v 1 && ! ($1 =~ ^-) ]]; then
                    MARKER="$1"
                else
                    echo >&2 "[X] Argument required: $arg"
                    HELP=1
                fi
                ;;
            -*)
                echo >&2 "[X] pathmungex: I don't understand \"$arg\""
                HELP=1
                ;;
            *)
                if [[ ! -v PATHVAR ]]; then
                    PATHVAR=$arg
                else
                    ENTRIES+=("$arg")
                fi
                ;;
        esac
    done

    if [[ ${#ENTRIES[@]} -eq 0 ]]; then
        echo >&2 "[X] pathumngex: Not enough arguments"
        HELP=1
    fi

    (shopt -oq verbose || shopt -oq xtrace) && declare -p PATHVAR EXPORT HELP CHECK WHERE MARKER ENTRIES

    if [[ -v HELP ]]; then
        cat <<- 'EOF'
			Add entries to a PATH-like list variable, for each entry that exists on disk
			and is not already in the list. By default, entries are inserted in order into
			PATHVAR before the first entry that begins with "/usr/".

			Usage: pathmungex [OPTIONS] PATHVAR ENTRIES...

			Parameters:
			PATHVAR     The name of a PATH-like list variable
			ENTRIES     One or more entries to add to PATHVAR

			Options:
			-e | --export       Export PATHVAR
			-a | --after        Append entries to the end of PATHVAR
			-b | --before       Prepend entries to the front of PATHVAR
			-f | --fail         Fail with an error and leave PATHVAR unmodified if any
			                    ENTRIES do not exist
			-n | --no-check     Do not check whether entries exist on disk
			-h | --help         Print this message and halt

			Optional arguments:
			-m | --marker MARKER    A pattern to use to find the entry in PATHVAR where
			                        ENTRIES should be inserted
			EOF
        return 1
    fi

    if [[ -v EXPORT ]]; then
        export "${PATHVAR?}"
    fi

    # collect good entries
    declare -a GOOD
    for item in "${ENTRIES[@]}"; do
        # if item is not in PATHVAR
        if [[ ! :${!PATHVAR:-}: =~ :$item: ]]; then
            if [[ $CHECK = nocheck || -e $item ]]; then
                GOOD+=("$item")
            elif [[ $CHECK = fail ]]; then
                echo >&2 "[!] pathmungex: entry does not exist: $item"
                return 1
            fi
        fi
    done

    # join all good entries
    # shellcheck disable=SC2155
    declare JOINED=$(
        IFS=:
        echo "${GOOD[*]}"
    )

    (shopt -oq verbose || shopt -oq xtrace) && declare -p GOOD JOINED

    # nothing to add?
    [[ -z $JOINED ]] && return

    # if PATHVAR is unset or empty...
    if [[ ! -v $PATHVAR || -z ${!PATHVAR} ]]; then
        # declare new global from PATHVAR reference set to joined entries
        declare -g "$PATHVAR=$JOINED"
        return
    elif [[ $WHERE = after ]]; then
        # modify global PATHVAR reference with joined entries appended
        declare -g "$PATHVAR=${!PATHVAR}:$JOINED"
        return
    elif [[ $WHERE = before ]]; then
        # modify global PATHVAR reference with joined entries prepended
        declare -g "$PATHVAR=$JOINED:${!PATHVAR}"
        return
    fi

    # not empty, before, or after; we'll have to split PATHVAR

    declare -a PATHARRAY FRONT BACK
    IFS=: read -ra PATHARRAY <<< "${!PATHVAR}"

    declare found
    for item in "${PATHARRAY[@]}"; do
        if [[ -v found || $item =~ $MARKER ]]; then
            found=1
            BACK+=("$item")
        else
            FRONT+=("$item")
        fi
    done

    # first build up an array
    PATHARRAY=("${FRONT[@]}" "${GOOD[@]}" "${BACK[@]}")

    (shopt -oq verbose || shopt -oq xtrace) && declare -p FRONT GOOD BACK

    # then join it together
    JOINED=$(
        IFS=:
        echo "${PATHARRAY[*]}"
    )

    declare -g "$PATHVAR=$JOINED"
}

setpath()
{
    if [[ $# -ne 2 ]]; then
        echo >&2 "Set a variable to a path if that path exists"
        echo >&2 "Usage: setpath VAR PATH"
        return 1
    elif [[ -e $2 ]]; then
        export "$1=$2"
    fi
}

sourcepath()
{
    if [[ $# -ne 1 || $1 =~ ^- ]]; then
        echo >&2 "Source a script if it exists"
        echo >&2 "Usage: sourcepath PATH"
        return 1
    elif [[ -e $1 ]]; then
        source "$1"
    fi
}

# showmounts()
# {
#     : 'list mounts in a table, and cut off the options'
#     mount -l "$@" | cut -d "(" -f 1 | sed -r "s/\<(on|type)\>/% \0/g" | column -t -s %
# }

flash_message()
{
    : 'breifly print a message to the screen'
    local arg message HELP
    local sleep=1
    while [[ $# -gt 0 ]]; do
        arg="$1"
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
                echo >&2 "Unrecognized option: $arg"
                ;;
            *)
                message+="$arg "
                ;;
        esac
    done

    if [[ -v HELP ]]; then
        command cat <<- EOF
			flash_message: briefly print a message to the screen.

			Usage: flash_message [-s|--sleep SLEEP] MESSAGE...
			    -s|--sleep: how long to sleep (currently $sleep)
			EOF
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
    : 'mnemonic: `jq | less`'
    jq -C "${@:-.}" | $_pager
}

yql()
{
    : 'mnemonic: `yq | less`'
    yq -C "${@:-.}" | $_pager
}

pkg-config-vars()
{
    : 'display all pkg-config variables for a name'
    for name in "$@"; do
        pkg-config "$name" --print-variables | while read -r var; do
            value=$(pkg-config "$name" --variable "$var")
            echo "$name: $var = $value"
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
    : 'like alias dush=`du -shxc`'
    command du -shxc "$@" | sort -h
}

dfh()
{
    : 'like alias dfh=`df -hT -t xfs -t ext4`'
    df -hT -t xfs -t ext4 "$@" | sort -h -k 4
}

each()
{
    : 'echo each argument'
    for item in "$@"; do
        echo "$item"
    done
}

showpaths()
{
    : 'pretty print pathlike variables'
    : 'usage: showpaths [PATHVAR...]'
    status=0

    # make a list of parameters, defaulting to just "PATH"
    paths=("${@:-PATH}")

    for item in "${paths[@]}"; do
        if [[ ! -v $item ]]; then
            # if there's no variable with that name, warn & continue
            echo >&2 "[X] showpaths: $item unset"
            status=1
            continue
        fi

        # if more than one argument, print a header
        [[ ${#paths[@]} -gt 1 ]] && echo "===== $item ====="
        # echo path variable contents, one per line
        echo "${!item}" | tr : "\n"
    done
    return $status
}
complete -v showpaths

searchpath()
{
    : 'search a pathlike variable'
    : 'usage: searchpath PATHVAR name [name...]'

    [[ $# -lt 2 ]] && return 1

    pathvar="$1"
    shift
    names=("$@")

    if [[ ! -v $pathvar ]]; then
        # if there's no variable with that name, explode
        echo >&2 "[X] searchpath: $pathvar unset"
        return 1
    fi

    # read contents of variable named by `pathvar` into array, separated by colons
    mapfile -td: pathlist <<< "${!pathvar}"

    for path in "${pathlist[@]}"; do
        for name in "${names[@]}"; do
            # expand any globs & print existing files
            compgen -G "$path/$name"
        done
    done

}
complete -v searchpath

fatal()
{
    : 'display an error with an optional message; stacktrace; exit 1'
    echo >&2 "[X] ${*:-Fatal Error}"
    stacktrace
    exit 1
}

stacktrace()
{
    : 'print the current call stack'
    local idx filename subroutine lineno lines ctx_lineno prefix

    local context=2 top=1 bottom=1

    local opt OPTARG OPTIND HELP
    while getopts :hc:t:b: opt; do
        case $opt in
            h) HELP=1 ;;
            c) context=$OPTARG ;;
            t) top=$OPTARG ;;
            b) bottom=$OPTARG ;;
            :)
                echo >&2 "[X] stacktrace: required argument not found: $OPTARG"
                HELP=1
                ;;
            ?)
                echo >&2 "[X] stacktrace: invalid option: $OPTARG"
                HELP=1
                ;;
            *)
                echo >&2 "[X] stacktrace: unexpected input"
                declare -p opt OPTARG
                HELP=1
                ;;
        esac
    done
    shift $((OPTIND - 1))

    if [[ -v HELP ]]; then
        cat >&2 <<- EOF
			${FUNCNAME[0]}: print a bash function stacktrace
			Usage: ${FUNCNAME[0]} [-h] [-c CONTEXT] [-b BOTTOM] [-t TOP]

			Options:
			-c CONTEXT      print CONTEXT number of lines of context (currently $context)
			-b BOTTOM       trim BOTTOM frames from the bottom of the stack (currently $bottom)
			-t TOP          trim TOP frames from the top of the stack (currently $top)
			EOF
        return 1
    fi

    echo "  Call stack (starting with oldest frame):"
    # iterating through 3 related arrays in reverse; -1 for array end ; idx > 0 to skip this function
    for ((idx = ${#BASH_SOURCE[@]} - bottom; idx >= top; idx--)); do
        filename=${BASH_SOURCE[$idx]}
        subroutine=${FUNCNAME[$idx]}
        lineno=${BASH_LINENO[$idx - 1]}

        unset lines
        # read into array $lines from $filename at $lineno
        # (such that $index = $lineno) with $context surrounding lines
        mapfile -s $((lineno - context - 1)) -O $((lineno - context)) -n $((context * 2 + 1)) -t lines < "$filename"

        echo "    $filename($subroutine):"
        for ctx_lineno in "${!lines[@]}"; do
            ((ctx_lineno == lineno)) && prefix="   >>" || prefix="     "
            echo "$prefix $ctx_lineno ${lines[$ctx_lineno]}"
        done

    done
}

faketty()
{
    : 'convince a command that it is attached to a tty'
    script -qefc "$(printf "%q " "$@")" /dev/null
}
complete -c faketty

mxtime()
{
    : 'get timestamps for maxar'
    [[ $# -gt 0 ]] && args=(--date "$*")
    date -Iseconds "${args[@]}" | sed 's/+0000/Z/'
}

# wrapper for pstree default arguments
pstree()
{
    [[ $# -eq 0 ]] && set -- -H $$ $$
    command pstree -Uas "$@"
}
