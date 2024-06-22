#!/usr/bin/env bash
# determine if we should start tmux

# [[ ${_SHELL_INTERACTIVE-} ]] || return 0

if [[ -v TURBO_MODE && ! -v TMUX ]] && havebin tmux; then
    # declare our intention to exec tmux
    # shellcheck disable=2034
    # _SHELL_EXPORT_ONLY=1
    unset _SHELL_INTERACTIVE
fi
