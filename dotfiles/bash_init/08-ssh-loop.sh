#!/bin/bash
# make an ssh to localhost loop

# if HAVE_POWERLINE_FONTS isn't already defined, check whether it should be
if [[ ! -v HAVE_POWERLINE_FONTS ]]; then
    if havebin fc-list && fc-list | grep -iqE "powerline|nerd"; then
        export HAVE_POWERLINE_FONTS=1
    fi
fi

if [[ ${_SHELL_INTERACTIVE-} &&
    ! ${SSH_CONNECTION-} &&
    ! ${TMUX-} &&
    ${TURBO_MODE-} ]]; then

    _if_verbose replace_exec
    exec ssh -t localhost
fi
