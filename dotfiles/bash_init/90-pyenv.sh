#!/bin/bash

if ! setpath -er PYENV_ROOT ~/.pyenv; then
    if [[ -f ~/.skip-pyenv ]]; then
        return 0
    fi

    if ! curl -fsSL https://github.com/pyenv/pyenv-installer/raw/master/bin/pyenv-installer | bash; then
        touch ~/.skip-pyenv
        return 1
    fi
fi

pathmungex --before --replace PATH "$PYENV_ROOT/shims"
pathmungex PATH "$PYENV_ROOT/bin"

export PYENV_SHELL=bash

function pyenv {
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

[[ ${_SHELL_INTERACTIVE-} ]] || return 0

# pathmungex -a BASH_COMPLETION_PATHS "$PYENV_ROOT/completions"
source "$PYENV_ROOT/completions/pyenv.bash"

declare -a func_lines
# if we succeed in reading the lines of the function `_pyenv` ...
if get_array func_lines declare -f _pyenv 2> /dev/null; then
    # and the last statement does not include "set +o noglob"
    if [[ ${func_lines[-2]} != *"set +o noglob"* ]]; then
        # remove the final closing brace
        unset 'func_lines[-1]'
        # wrap the function body in in `set -o noglob` and `set +o noglob`
        func_lines=("${func_lines[@]::2}" "set -o noglob" "${func_lines[@]:2}" "set +o noglob" "}")
        # and re-evaluate the reconstructed function
        eval "$(each "${func_lines[@]}")"
    fi
fi
unset func_lines
