#!/bin/bash

setpath RBENV_ROOT ~/.rbenv || return 0

pathmungex --before --replace PATH "$HOME/.rbenv/shims" "$HOME/.rbenv/bin"
pathmungex -a BASH_COMPLETION_DIRS "$HOME/.rbenv/completions"
export RBENV_SHELL=bash

rbenv()
{
    local command="${1:-}"
    shift || true

    case "$command" in
        rehash | shell) eval "$(command rbenv "sh-$command" "$@")" ;;
        *) command rbenv "$command" "$@" ;;
    esac
}
