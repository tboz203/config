#!/bin/bash

/usr/bin/which pyenv &>/dev/null || return

PATH="$(bash --norc -ec 'IFS=:; paths=($PATH); for i in ${!paths[@]}; do if [[ ${paths[i]} == "'/home/tbozeman/.pyenv/plugins/pyenv-virtualenv/shims'" ]]; then unset '\''paths[i]'\''; fi; done; echo "${paths[*]}"')"

# generated by `pyenv virtualenv-init -`
# pyenv-virtualenv 1.2.1

export PATH="/home/tbozeman/.pyenv/plugins/pyenv-virtualenv/shims:${PATH}";
export PYENV_VIRTUALENV_INIT=1;
_pyenv_virtualenv_hook() {
  local ret=$?
  if [ -n "${VIRTUAL_ENV-}" ]; then
    eval "$(pyenv sh-activate --quiet || pyenv sh-deactivate --quiet || true)" || true
  else
    eval "$(pyenv sh-activate --quiet || true)" || true
  fi
  return $ret
};
if ! [[ "${PROMPT_COMMAND-}" =~ _pyenv_virtualenv_hook ]]; then
  PROMPT_COMMAND="_pyenv_virtualenv_hook;${PROMPT_COMMAND-}"
fi
