#!/bin/bash

return 0

if ! setpath -er RBENV_ROOT ~/.rbenv; then
    if [[ -f ~/.skip-rbenv ]]; then
        return 0
    fi

    if ! curl -fsSL https://github.com/rbenv/rbenv-installer/raw/HEAD/bin/rbenv-installer | bash; then
        touch ~/.skip-rbenv
        return 1
    fi
fi

pathmungex --before --replace PATH "$RBENV_ROOT/shims"
pathmungex PATH "$RBENV_ROOT/bin"
pathmungex BASH_COMPLETION_LOAD_PATH "$RBENV_ROOT/completions"
export RBENV_SHELL=bash

pathmungex -e RBENV_HOOK_PATH "$HOME/.local/share/rbenv-hooks"

function rbenv {
    local command="${1:-}"
    shift || true

    case "$command" in
        rehash | shell) eval "$(command rbenv "sh-$command" "$@")" ;;
        *) command rbenv "$command" "$@" ;;
    esac
}
