#!/bin/bash
# shellcheck disable=2317

# disabling this because it slows down PROMPT_COMMAND *so freaking much*
return 0

setpath -er PYENV_VIRTUALENV_ROOT "${PYENV_ROOT?}/plugins/pyenv-virtualenv" || return 0

pathmungex --before --replace PATH "$PYENV_VIRTUALENV_ROOT/shims"
pathmungex PATH "$PYENV_VIRTUALENV_ROOT/bin"
export PYENV_VIRTUALENV_INIT=1

function _pyenv_virtualenv_hook {
    local ret=$?
    if [[ ${VIRTUAL_ENV-} ]]; then
        eval "$(command pyenv sh-activate --quiet || command pyenv sh-deactivate --quiet || true)" || true
    else
        eval "$(command pyenv sh-activate --quiet || true)" || true
    fi
    return "$ret"
}

[[ ${PROMPT_COMMAND-} == *_pyenv_virtualenv_hook* ]] || PROMPT_COMMAND+=$'\n_pyenv_virtualenv_hook'
