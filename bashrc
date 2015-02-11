# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# with modifications by tboz203

# If not running interactively, don't do anything
[[ -z "$PS1" ]] && return

# # fix the term, specifically for tmux (otherwise powerline doesn't work well)
# if [[ $TERM != *256color && \
#         $COLORTERM == "gnome-terminal" || \
#         $COLORTERM == "xfce4-terminal" ]]; then
#     export TERM=xterm-256color
# elif [[ $COLORTERM == "rxvt-xpm" ]]; then
#     export TERM=rxvt-256color
# fi

# hotfix for cygwin
if [[ $TERM != screen* ]]; then
    export TERM=xterm-256color
fi

# set powerline availability flag (for all programs)
if ( which powerline >& /dev/null ) ; then
    if [[ -z $SSH_CONNECTION && $TERM == *256color && $HAS_POWERLINE_FONTS ]]; then
        # if we're over ssh, then `HAS_POWERLINE` will already be set
        # appropriately. otherwise the local box needs to support it
        export HAS_POWERLINE=1
    fi
else
    unset HAS_POWERLINE
fi

if [[ $HAS_POWERLINE ]]; then
    # TODO: this could probably be streamlined, but it works
    if [[ -d /usr/local/lib/python2.7/dist-packages/powerline ]]; then
        export POWERLINE_ROOT=/usr/local/lib/python2.7/dist-packages/powerline
    elif [[ -d $HOME/.local/lib/python2.7/site-packages/powerline ]]; then
        export POWERLINE_ROOT=$HOME/.local/lib/python2.7/site-packages/powerline
    else
        echo >2 "[-] Powerline root not found"
        unset HAS_POWERLINE
    fi
fi

# if has tmux and not nested, change process to new session
if [[ -x $(which tmux) ]] && [[ -z "$TMUX" ]]; then
    exec tmux
fi

umask 077

# ignore something-or-other (i think it's `ls` and `cd`?)
HISTCONTROL=ignoreboth
# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=5000
HISTFILESIZE=100000
HISTTIMEFORMAT="%h %d %H:%M:%S> "
HISTIGNORE="ls:la:lf:ll:l"

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# make less more friendly for non-text input files, see lesspipe(1)
[[ -x /usr/bin/lesspipe ]] && eval "$(SHELL=/bin/sh lesspipe)"

# set our prompt, depending on powerline availability
if [[ -z $HAS_POWERLINE ]]; then
    # no powerline # {{{
    # set variable identifying the chroot you work in (used in the prompt below)
    if [[ -z "$debian_chroot" && -r /etc/debian_chroot ]]; then
        debian_chroot=$(cat /etc/debian_chroot)
    fi

    # set a fancy prompt (non-color, unless we know we "want" color)
    case "$TERM" in
        xterm-color) color_prompt=yes;;
    esac

    # uncomment for a colored prompt, if the terminal has the capability
    force_color_prompt=yes

    if [[ $force_color_prompt ]]; then
        if [[ -x /usr/bin/tput ]] && tput setaf 1 >& /dev/null; then
            # We have color support; assume it's compliant with Ecma-48
            # (ISO/IEC-6429). (Lack of such support is extremely rare, and such
            # a case would tend to support setf rather than setaf.)
            color_prompt=yes
        else
            color_prompt=
        fi
    fi

    if [ "$color_prompt" = yes ]; then #{{{
        # some expansions i made, trying some stuff out for PS1
        black="$(tput sgr0 && tput setaf 0)"
        BLACK="$(tput bold && tput setaf 0)"
        red="$(tput sgr0 && tput setaf 1)"
        RED="$(tput bold && tput setaf 1)"
        green="$(tput sgr0 && tput setaf 2)"
        GREEN="$(tput bold && tput setaf 2)"
        yellow="$(tput sgr0 && tput setaf 3)"
        YELLOW="$(tput bold && tput setaf 3)"
        blue="$(tput sgr0 && tput setaf 4)"
        BLUE="$(tput bold && tput setaf 4)"
        magenta="$(tput sgr0 && tput setaf 5)"
        MAGENTA="$(tput bold && tput setaf 5)"
        cyan="$(tput sgr0 && tput setaf 6)"
        CYAN="$(tput bold && tput setaf 6)"
        white="$(tput sgr0 && tput setaf 7)"
        WHITE="$(tput bold && tput setaf 7)"
        reset="$(tput sgr0)"
    else
        black="\e[0;30m"
        BLACK="\e[1;30m"
        red="\e[0;31m"
        RED="\e[1;31m"
        green="\e[0;32m"
        GREEN="\e[1;32m"
        yellow="\e[0;33m"
        YELLOW="\e[1;33m"
        blue="\e[0;34m"
        BLUE="\e[1;34m"
        magenta="\e[0;35m"
        MAGENTA="\e[1;35m"
        cyan="\e[0;36m"
        CYAN="\e[1;36m"
        white="\e[0;37m"
        WHITE="\e[1;37m"
        reset="\e[0m"
    fi #}}}

    u_color="$([[ "$EUID" -eq 0 ]] && echo "$RED" || echo "$GREEN")"
    PS1="\[$reset\]$debian_chroot\[$u_color\]\u\[$WHITE\]@\[$GREEN\]\h\[$WHITE\]:"
    PS1+="\[$BLUE\]\w\[$reset\]"
    PS1+='$(__git_ps1 ":(%s)")\$ '
    unset red RED green GREEN yellow YELLOW blue BLUE magenta MAGENTA cyan CYAN
    unset white WHITE reset color_prompt force_color_prompt

    # list files on directory change
    PROMPT_COMMAND='[[ ${__new_wd:=$PWD} != $PWD ]] && ll; __new_wd=$PWD'

    if [[ -f ~/.git-prompt ]]; then
        . ~/.git-prompt
        GIT_PS1_SHOWDIRTYSTATE=1
        GIT_PS1_SHOWSTASHSTATE=1
        GIT_PS1_SHOWUNTRACKEDFILE=1
        GIT_PS1_SHOWCOLORHINTS=1
    fi #}}}
else
    # we have powerline #{{{
    powerline-daemon -q
    export POWERLINE_BASH_CONTINUATION=1
    export POWERLINE_BASH_SELECT=1
    .  $POWERLINE_ROOT/bindings/bash/powerline.sh #}}}
fi

# set autocd: if command is a directory, cd to it
shopt -s autocd

# Alias definitions.
if [[ -f ~/.bash_aliases ]]; then
    . ~/.bash_aliases
fi

# Function definitions.
if [[ -f ~/.bash_functions ]]; then
    . ~/.bash_functions
fi

# Enable programmable completion features.
if [[ -f /etc/bash_completion ]] && ! shopt -oq posix; then
    . /etc/bash_completion
fi

if [[ -d $HOME/.local/bin && $PATH != *$HOME/.local/bin* ]]; then
    export PATH=$HOME/.local/bin:$PATH
fi

if [[ -d $HOME/.bin && $PATH != *$HOME/.bin* ]]; then
    export PATH=$HOME/.bin:$PATH
fi

# dircolors
if [[ -x /usr/bin/dircolors ]]; then
    if [[ -r ~/.dircolors ]]; then
        eval "$(dircolors -b ~/.dircolors)"
    else
        eval "$(dircolors -b)"
    fi
fi

# # clear screen and list files after changing directory #{{{
# # this functionality is obsoleted by the PROMPT_COMMAND
# cd(){
#     if [ -n "$1" ]; then
#         builtin cd "$1"
#     else
#         builtin cd "$HOME"
#     fi
#     clear
#     ll
# } #}}}

# a function to open files using the default file handler
open () {
    for item in "$@"; do
        explorer.exe "$item"
    done
}

# vim: foldmethod=marker
