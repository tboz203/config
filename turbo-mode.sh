#!/bin/bash
# scriptlet to be sourced by bashrc to start ssh, tmux, and powerline

# compgen -v | sort | while read name; do declare -p $name ; done
# set -vx

# fix TERM for tmux
if [[ $TERM != *256color && $COLORTERM == @(gnome-terminal|xfce4-terminal|truecolor) ]]; then
    export TERM=xterm-256color
elif [[ $COLORTERM == rxvt-xpm ]]; then
    export TERM=rxvt-256color
fi

if [[ ! -v SSH_CONNECTION && ! -v HAS_POWERLINE_FONTS ]] && ( fc-list | grep -iq powerline ) ; then
    export HAS_POWERLINE_FONTS=1
fi

# special logic for maxar vdi: put an ssh connection between the user and tmux,
# so that (hopefully) the tmux session will persist through vdi disconnects
if [[ $HOSTNAME =~ pu00[cg]envdi && ! -v SSH_CONNECTION && ! -v TMUX && -v TURBO_MODE ]]; then
    exec ssh localhost
fi

# set powerline availability flag (for all programs)
if [[ -x $( 'which' powerline 2>/dev/null ) && $TERM == *256color && $HAS_POWERLINE_FONTS ]]; then
    export HAS_POWERLINE=1
fi

# if this isn't working and you don't know why, make sure that
# `HAS_POWERLINE_FONTS` survives the ssh connection

if [[ $HAS_POWERLINE ]]; then
    _DIRS=(
        $HOME/.local/lib/python*
        /usr/local/lib/python*
        /usr/lib/python*
    )
    for _dir in "${_DIRS[@]}"; do
        if [[ -d $_dir/site-packages/powerline ]]; then
            export POWERLINE_ROOT=$_dir/site-packages/powerline
            break
        fi
    done
    if [[ -z $POWERLINE_ROOT ]]; then
        echo >&2 "[-] Powerline root not found"
        read -p "press enter to continue: "
        unset HAS_POWERLINE
    fi
    unset _DIRS _dir
fi

# if we have tmux and we're not nested, change process to new session
if [[ -x $('which' tmux 2>/dev/null) && ! -v TMUX && -v TURBO_MODE ]]; then
    exec tmux new-session -A -s main
fi

# set our prompt, depending on powerline availability
if [[ -v HAS_POWERLINE ]]; then
    powerline-daemon -q
    # export POWERLINE_BASH_CONTINUATION=1
    # export POWERLINE_BASH_SELECT=1
    . $POWERLINE_ROOT/bindings/bash/powerline.sh
else
    if [[ -f ~/.pretty_prompt.sh ]]; then
        . ~/.pretty_prompt.sh
    else
        PS1='\[\e[1;33m\]\u@\h \w \$ \[\e[0m\]'
    fi
fi

# set +vx
