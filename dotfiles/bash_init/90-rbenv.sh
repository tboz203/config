#!/bin/bash

setpath -er RBENV_ROOT ~/.rbenv || return 0

pathmungex --before --replace PATH "$RBENV_ROOT/shims"
pathmungex PATH "$RBENV_ROOT/bin"
# pathmungex -a BASH_COMPLETION_PATHS "$RBENV_ROOT/completions/rbenv.bash"
export RBENV_SHELL=bash

rbenv() {
    local command="${1:-}"
    shift || true

    case "$command" in
        rehash | shell) eval "$(command rbenv "sh-$command" "$@")" ;;
        *) command rbenv "$command" "$@" ;;
    esac
}
