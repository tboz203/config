# bash functions

# [[ ${_SHELL_INTERACTIVE-} ]] || return 0

withenv() {
    # execute a command with `.env` sourced
    local -a envfiles
    get_array envfiles searchparents -a .env || true
    local path
    for path in "${envfiles[@]}"; do
        source "$path"
    done
    "$@"
}

vimfiles() {
    # edit all regular files (in $@ or .) with vim
    with_files vim -- "$@"
} && complete -d vimfiles

vimwhich() {
    local -a targets
    get_array targets type -P "$@" || return
    vim "${targets[@]}"
} && complete -c vimwhich

nvfiles() {
    with_files nvim -- "$@"
} && complete -d nvfiles

nvwhich() {
    local -a targets
    get_array targets type -P "$@" || return
    nvim "${targets[@]}"
} && complete -c nvwhich

mw() {
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

ALT_PAGER=$(type -P bat || type -P less)

jql() {
    # mnemonic: `jq | less`
    jq -C "${@:-.}" | "$ALT_PAGER"
}

yql() {
    # mnemonic: `yq | less`
    yq -C "${@:-.}" | "$ALT_PAGER"
}

hdl() {
    # mnemonic: `hd | less`
    hd "$@" | "$ALT_PAGER"
}

dush() {
    # like alias dush=`du -shxc`
    command du -shxc "$@" | sort -h
} && complete -d dush

dfh() {
    # like alias dfh=`df -hT -t xfs -t ext4`
    df -hT -t xfs -t ext4 "$@" | sort -h -k 4
}

faketty() {
    # convince a command that it is attached to a tty
    script -qefc "$(printf "%q " "$@")" /dev/null
} && complete -c faketty

mxtime() {
    # get timestamps for maxar
    local -a args
    (($# > 0)) && args=(--date "$*")
    date -Iseconds "${args[@]}" | sed 's/+0000/Z/'
}

pstree() {
    # wrapper for pstree default arguments
    (($# == 0)) && set -- -H $$ $$
    command pstree -Uas "$@"
}

unalias which &> /dev/null || true
which() {
    {
        alias -p
        declare -f
    } | command which --tty-only --read-alias --read-alias --read-functions --show-dot --show-tilde "$@"
}

snip() {
    if [[ $# -gt 1 || ${1-} == -* ]]; then
        _err "Snip lines from the middle"
        _err "Usage: ${FUNCNAME[0]} [COUNT]"
        return 2
    fi
    local count=${1:-10}
    local -a lines
    readarray -t -n "$count" lines || return 1
    each "${lines[@]}"
    echo "..."
    tail -n "$count"
}

# make() {
#     bear intercept --force-wrapper -- make -j "$(nproc)" "$@"
#     local retval=$?
#     bear citnames --append
#     return $retval
# }
#
nvfd() {
    local -a files
    get_array files fd --type file "$@" || return
    nv "${files[@]}"
}

nvrg() {
    local -a files
    get_array files rg -l "$@" || return
    nv "${files[@]}"
}
