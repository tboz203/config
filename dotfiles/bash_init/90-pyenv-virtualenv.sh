#!/bin/bash
# shellcheck disable=2317

# disabling this because it slows down PROMPT_COMMAND *so freaking much*
return 0

setpath PYENV_VIRTUALENV_ROOT "$PYENV_ROOT/plugins/pyenv-virtualenv" || return 0

pathmungex --before --replace PATH "$PYENV_VIRTUALENV_ROOT/shims"
pathmungex PATH "$PYENV_VIRTUALENV_ROOT/bin"
export PYENV_VIRTUALENV_INIT=1

_pyenv_virtualenv_hook()
{
    local ret=$?
    if [ -n "${VIRTUAL_ENV-}" ]; then
        eval "$(command pyenv sh-activate --quiet || pyenv sh-deactivate --quiet || true)" || true
    else
        eval "$(command pyenv sh-activate --quiet || true)" || true
    fi
    return $ret
}

if ! [[ "${PROMPT_COMMAND-}" =~ _pyenv_virtualenv_hook ]]; then
    PROMPT_COMMAND="_pyenv_virtualenv_hook;${PROMPT_COMMAND-}"
fi
