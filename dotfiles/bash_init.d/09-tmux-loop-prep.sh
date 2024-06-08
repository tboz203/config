#!/usr/bin/env bash
# determine if we should start tmux

# if we have tmux and we're not nested
if [[ -v TURBO_MODE && ! -v TMUX ]] && haveexe tmux; then
    # declare our intention to exec tmux
    # shellcheck disable=2034
    declare -g EXPORT_ONLY=1
fi
