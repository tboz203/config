#!/bin/bash

setpath -er PYENV_ROOT ~/.pyenv || return 0

pathmungex --before --replace PATH "$PYENV_ROOT/shims"
pathmungex PATH "$PYENV_ROOT/bin"
# pathmungex -a BASH_COMPLETION_PATHS "$PYENV_ROOT/completions/pyenv.bash"

export PYENV_SHELL=bash

pyenv() {
    local command
    command="${1:-}"
    if [ "$#" -gt 0 ]; then
        shift
    fi

    case "$command" in
        activate | deactivate | rehash | shell)
            eval "$(command pyenv "sh-$command" "$@")"
            ;;
        *)
            command pyenv "$command" "$@"
            ;;
    esac
}
