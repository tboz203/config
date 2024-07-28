#!/bin/bash

if ! setpath -er NODENV_ROOT ~/.nodenv; then
    if [[ -f ~/.skip-nodenv ]]; then
        return 0
    fi

    if ! curl -fsSL https://github.com/nodenv/nodenv-installer/raw/HEAD/bin/nodenv-installer | bash; then
        touch ~/.skip-nodenv
        return 1
    fi
fi

pathmungex --before --replace PATH "$NODENV_ROOT/shims"
pathmungex PATH "$NODENV_ROOT/bin"
# pathmungex -a BASH_COMPLETION_PATHS "$NODENV_ROOT/completions/nodenv.bash"

export NODENV_SHELL=bash

nodenv() {
    local command="${1:-}"
    shift || true

    case "$command" in
        rehash | shell) eval "$(command nodenv "sh-$command" "$@")" ;;
        *) command nodenv "$command" "$@" ;;
    esac
}
