#!/bin/bash

setpath -er NODENV_ROOT ~/.nodenv || return 0

pathmungex --before --replace PATH "$NODENV_ROOT/shims"
pathmungex PATH "$NODENV_ROOT/bin"
# pathmungex -a BASH_COMPLETION_PATHS "$NODENV_ROOT/completions/nodenv.bash"

export NODENV_SHELL=bash

nodenv()
{
    local command="${1:-}"
    shift || true

    case "$command" in
        rehash | shell) eval "$(command nodenv "sh-$command" "$@")" ;;
        *) command nodenv "$command" "$@" ;;
    esac
}
