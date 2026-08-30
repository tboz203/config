# "helper" functions
# (functions that may also be useful in scripting)

function withenv {
    # execute a command with `.env` sourced
    local -a envfiles
    get_array envfiles searchparents -a .env || true
    local path
    for path in "${envfiles[@]}"; do
        source "$path"
    done
    "$@"
}

function mw {
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

function faketty {
    # convince a command that it is attached to a tty
    script -qefc "$(printf "%q " "$@")" /dev/null
} && complete -c faketty

# unalias which &> /dev/null || true
# function which {
#     {
#         alias -p
#         declare -f
#     } | command which --tty-only --read-alias --read-alias --read-functions --show-dot --show-tilde "$@"
# }

function snip {
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

# function make {
#     bear intercept --force-wrapper -- make -j "$(nproc)" "$@"
#     local retval=$?
#     bear citnames --append
#     return $retval
# }

function pkg-config-vars {
    # display all pkg-config variables for a name
    local -a names
    get_array names pkg-config-names
    local glob
    for glob in "$@"; do
        local name
        for name in "${names[@]}"; do
            # shellcheck disable=2053  # the globbing is the point
            [[ $name == $glob ]] || continue
            local -a vars
            get_array vars pkg-config "$name" --print-variables
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

function pkg-config-names {
    pkg-config --list-all | cut -f1 -d" " | sort -u
}

function _complete-pkg-config-names {
    # mapfile -t COMPREPLY < <(compgen -W "$(pkg-config-names)" -- "${COMP_WORDS[COMP_CWORD]}")
    get_array COMPREPLY compgen -W "$(pkg-config-names)" -- "${COMP_WORDS[COMP_CWORD]}"
}

complete -F _complete-pkg-config-names pkg-config-vars
