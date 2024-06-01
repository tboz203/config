#!/bin/bash
# scriptlet to be sourced by bashrc to start ssh, tmux, and powerline

# If not running interactively, do nothing
[[ $- == *i* ]] || return

# _start_debug_trace

# fix TERM for tmux
# if [[ $TERM != *256color && $COLORTERM == @(gnome-terminal|xfce4-terminal|truecolor) ]]; then
#     export TERM=xterm-256color
# elif [[ $COLORTERM == rxvt-xpm ]]; then
#     export TERM=rxvt-256color
# fi

# set powerline availability flag (for all programs)
if haveexe powerline && [[ ($TERM == *256color || $COLORTERM == truecolor) && $HAS_POWERLINE_FONTS ]]; then
    export HAS_POWERLINE=1
fi

# if this isn't working and you don't know why, make sure that
# `HAS_POWERLINE_FONTS` survives the ssh connection

if [[ -v HAS_POWERLINE ]]; then
    dirs=(
        "$HOME"/.local/lib/python*
        /usr/local/lib/python*
        /usr/lib/python*
    )
    for dir in "${dirs[@]}"; do
        candidate="$dir/site-packages/powerline"
        if [[ -d $dir && -d $candidate ]]; then
            export POWERLINE_ROOT="$candidate"
            break
        fi
    done
    if [[ ! -v POWERLINE_ROOT ]]; then
        unset HAS_POWERLINE
        echo >&2 "[!] Powerline root not found"
    fi
    unset dirs dir
fi

# if we have tmux and we're not nested, change process to new session
if haveexe tmux && [[ ! -v TMUX && -v TURBO_MODE ]]; then
    exec tmux new-session -A -s main || {
        echo >&2 "[!] exec tmux failed"
        return 1
    }
fi

# set our prompt, depending on powerline availability
if [[ -v HAS_POWERLINE ]]; then
    powerline-daemon -q || true
    # export POWERLINE_BASH_CONTINUATION=1
    # export POWERLINE_BASH_SELECT=1
    . "$POWERLINE_ROOT/bindings/bash/powerline.sh"
else
    if [[ -f ~/.pretty_prompt.sh ]]; then
        . ~/.pretty_prompt.sh
    else
        PS1='\[\e[1;33m\]\u@\h \w \$ \[\e[0m\]'
    fi
fi
