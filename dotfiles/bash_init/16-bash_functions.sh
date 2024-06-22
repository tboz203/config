# bash functions

# [[ ${_SHELL_INTERACTIVE-} ]] || return 0

fatal()
{
    # display an error with an optional message; stacktrace; exit 1
    echo >&2 "[X] ${*:-Fatal Error}"
    stacktrace
    exit 1
}

withenv()
{
    # execute a command with `.env` sourced
    local -a envfiles
    get_array envfiles searchparents -a .env || true
    local path
    for path in "${envfiles[@]}"; do
        source "$path"
    done
    "$@"
}

vimfiles()
{
    # edit all regular files (in $@ or .) with vim
    with_files vim -- "$@"
} && complete -d vimfiles

vimwhich()
{
    local -a targets
    get_array targets type -P "$@" || return
    vim "${targets[@]}"
} && complete -c vimwhich

nvfiles()
{
    with_files nvim -- "$@"
} && complete -d nvfiles

nvwhich()
{
    local -a targets
    get_array targets type -P "$@" || return
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
