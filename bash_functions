#!/bin/bash

doihave () {
     /usr/bin/which &> /dev/null "$@"
}
# so i can type `if ihave program; ...`
alias ihave=doihave

heregit() {
    # execute a git command in every child directory
    for item in *; do
        echo -e "\e[30;43m> $item\e[0m"
        git -C $item "$@"
        echo
    done
}

files() {
    # like `find -type f`, but exclude hidden files
    find "$@" -iregex ".*/\.[^/].*" -prune -o -type f -print
}

# alias vimfiles='vim $(files)'
vimfiles() {
    vim $( files "$@" )
}

# mnemonic "move with"
# move a file & cd to that directory
mw() {
    if [[ $# -lt 2 || " $@ " =~ " -h " || " $@ " =~ " --help " ]]; then
        echo "mw: FILE... DIR -> mv FILE... DIR && cd DIR"
        exit 1
    fi
    # the last parameter
    dest="${@: -1}"
    # everything but the last parameter, as an array
    files=( "${@:1:$#-1}" )
    [[ -d $dest ]] || { echo "last parameter should be a directory" ; return 1 ; }
    mv -t "$dest" "${files[@]}" && cd "$dest"
}

realwhich() {
    realpath $(/usr/bin/which "$@")
}

repeat() {
    # usage: repeat TEXT COUNT
    # does something a bit like `TEXT * COUNT`
    local text="$1"
    local count="$2"
    printf "${text}%.0s" $(seq 1 $count)
}

pathmunge () {
    # add a directory to the PATH if not already present
    case ":${PATH}:" in
        *:"$1":*)
            ;;
        *)
            if [ -d "$1" ] ; then
                if [ "$2" = "after" ] ; then
                    PATH=$PATH:$1
                else
                    PATH=$1:$PATH
                fi
            fi
    esac
}

pathmungex () {
    # like pathmunge, but better
    local PATHVAR DIR EXPORT AFTER HELP
    params=( PATHVAR DIR )
    while [[ $# -gt 0 ]]; do
        arg="$1"; shift
        case $arg in
            (-e|--export) EXPORT=1 ;;
            (-a|--after) AFTER=1 ;;
            (-h|--help) HELP=1 ;;
            (-*)
                echo >&2 "[X] I don't understand \"$arg\""
                HELP=1
            ;;
            (*)
                : "setting a positional parameter: ${params[0]} -> $arg"
                if [[ ${#params[@]} -gt 0 ]]; then
                    param="${params[0]}"
                    declare "$param=$arg"
                    params=("${params[@]:1}")
                else
                    echo >&2 "[X] Too many parameters: \"$arg\""
                    HELP=1
                fi
            ;;
        esac
    done

    if [[ ${#params[@]} -gt 0 ]]; then
        echo >&2 "[X] Not enough parameters"
        HELP=1
    fi

    : "PATHVAR is ${PATHVAR:-<unset>}"
    : "DIR is ${DIR:-<unset>}"
    : "AFTER is ${AFTER:-<unset>}"
    : "EXPORT is ${EXPORT:-<unset>}"

    if [[ -v HELP ]]; then
        echo "usage: pathmungex [-e|--export] [-a|--after] PATHVAR DIR"
        echo
        echo "Add a directory to a path variable if that directory exists, and is not already in that path"
        echo "example: pathmungex -a PATH $HOME/.bin -e"
        return 1
    fi

    # DIR=$( realpath -msq "$DIR")

    if [[ ! (:${!PATHVAR}: =~ :$DIR:) && -d $DIR ]]; then
        if [[ ! -v $PATHVAR ]]; then
            declare -g "$PATHVAR=$DIR"
        elif [[ -v AFTER ]]; then
            declare -g "$PATHVAR=${!PATHVAR}:$DIR"
        else
            declare -g "$PATHVAR=$DIR:${!PATHVAR}"
        fi
        if [[ -v EXPORT ]]; then
            export $PATHVAR
        fi
    fi
}

showmounts() {
    # list mounts in a table, and cut off the options
    mount -l "$@" | cut -d "(" -f 1 | sed -r "s/\<(on|type)\>/% \0/g" | column -t -s %
}

