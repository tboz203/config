#!/usr/bin/env bash
# determine if we should start tmux

if [[ ${_SHELL_INTERACTIVE-} &&
    ! ${TMUX-} &&
    ${TURBO_MODE-} ]] &&
    havebin tmux; then

    # declare our intention to exec tmux
    unset _SHELL_INTERACTIVE
    declare -g _SHELL_EXEC_TMUX=1
fi
