#!/bin/bash
# make an ssh to localhost loop

# If not running interactively, do nothing
[[ $- == *i* ]] || return 0

# _debug_trace

if [[ ! -v SSH_CONNECTION && ! -v HAS_POWERLINE_FONTS ]] && (fc-list | grep -iE "powerline|nerd" &> /dev/null); then
    export HAS_POWERLINE_FONTS=1
fi

# special logic for maxar vdi: put an ssh connection between the user and tmux,
# so that (hopefully) the tmux session will persist through vdi disconnects
if [[ ! -v SSH_CONNECTION && ! -v TMUX && -v TURBO_MODE ]]; then
    replace_exec
    exec ssh -t localhost || {
        echo >&2 "[!] exec ssh failed"
        sleep 5
        return 1
    }
fi
