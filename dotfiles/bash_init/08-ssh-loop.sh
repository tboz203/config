#!/bin/bash
# make an ssh to localhost loop

# if HAS_POWERLINE_FONTS isn't already defined, check whether it should be
if [[ ! -v HAS_POWERLINE_FONTS ]]; then
    if fc-list | grep -iqE "powerline|nerd"; then
        export HAS_POWERLINE_FONTS=1
    fi
fi

[[ ${_SHELL_INTERACTIVE-} && ! ${SSH_CONNECTION-} ]] || return 0

if [[ ! -v TMUX && -v TURBO_MODE ]]; then
    _if_verbose replace_exec
    exec ssh -t localhost
fi
