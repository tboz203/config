#!/bin/bash

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
