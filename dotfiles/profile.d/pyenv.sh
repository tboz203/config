#!/bin/bash

pathmungex PATH "$HOME/.pyenv/bin"

/usr/bin/which pyenv &>/dev/null || return

export PYENV_ROOT=$HOME/.pyenv

eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"
