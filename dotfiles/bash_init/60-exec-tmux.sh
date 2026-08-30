#!/usr/bin/env bash
# determine if we should exec tmux

if [[ ${_SHELL_INTERACTIVE-} && ! ${TMUX-} && ${TURBO_MODE-} ]] && havebin tmux; then
    _if_verbose replace_exec
    exec tmux new-session -A -s main
fi
