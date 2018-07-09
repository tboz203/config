# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc) for examples
# with modifications by tboz203
# vim: tw=119

# If not running interactively, don't do anything
case $- in
    *i*) ;;
    *) return ;;
esac

# if has tmux and not nested, change process to new session
if [[ -x /usr/bin/tmux ]] && [[ -z "$TMUX" ]] && [[ -z $NO_TMUX ]]; then
    # fix TERM for tmux (otherwise powerline doesn't work well)
    if [[ $TERM != *256color && $COLORTERM == gnome-terminal || $COLORTERM == xfce4-terminal ]]; then
        export TERM=xterm-256color
    elif [[ $COLORTERM == rxvt-xpm ]]; then
        export TERM=rxvt-256color
    fi

    # set powerline availability flag (for all programs)
    if [[ $(which powerline) && $TERM == *256color && $HAS_POWERLINE_FONTS ]]; then
        export HAS_POWERLINE=1
    fi

    shopt -s nullglob

    if [[ $HAS_POWERLINE ]]; then
        for _location in {/usr,/usr/local,$HOME/.local}/lib/python*/site-packages/powerline; do
            _root=$_location
        done
        if [[ $_root ]]; then
            export POWERLINE_ROOT=$_root
        else
            echo >&2 "[-] Powerline root not found"
            read -p "press enter to continue: "
            unset HAS_POWERLINE
        fi
        unset _location _root
    fi

    exec /usr/bin/tmux new-session -A -s main
fi

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
if [[ $HAS_POWERLINE ]]; then
    powerline-daemon -q
    export POWERLINE_BASH_CONTINUATION=1
    export POWERLINE_BASH_SELECT=1
    .  $POWERLINE_ROOT/bindings/bash/powerline.sh
else

    case "$TERM" in
        *color*) color_prompt=yes;;
    esac

    if [ "$color_prompt" = yes ]; then
        black="\[\e[0;30m\]"
        BLACK="\[\e[1;30m\]"
        red="\[\e[0;31m\]"
        RED="\[\e[1;31m\]"
        green="\[\e[0;32m\]"
        GREEN="\[\e[1;32m\]"
        yellow="\[\e[0;33m\]"
        YELLOW="\[\e[1;33m\]"
        blue="\[\e[0;34m\]"
        BLUE="\[\e[1;34m\]"
        magenta="\[\e[0;35m\]"
        MAGENTA="\[\e[1;35m\]"
        cyan="\[\e[0;36m\]"
        CYAN="\[\e[1;36m\]"
        white="\[\e[0;37m\]"
        WHITE="\[\e[1;37m\]"
        reset="\[\e[0m\]"
    fi

    u_color="$([[ "$EUID" -eq 0 ]] && echo "$RED" || echo "$GREEN")"
    PS1="${u_color}\u${WHITE}@${GREEN}\h${WHITE} ${BLUE}\w${reset}"
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
        PS1+='$(__git_ps1 ":(%s)")'
    fi

    PS1+="${WHITE}$ ${reset}"
fi

# set autocd: if command is a directory, cd to it
shopt -s autocd
# set recursive globbing w/ "**"
shopt -s globstar

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

# dircolors
if [[ -x /usr/bin/dircolors ]]; then
    if [[ -r ~/.dircolors ]]; then
        eval "$(dircolors -b ~/.dircolors)"
    else
        eval "$(dircolors -b)"
    fi
fi

if [[ -x $(which thefuck) ]]; then
    eval "$(thefuck --alias drat)"
fi

if [[ -x $(which pipenv) ]]; then
    eval "$(pipenv --completion)"
fi

# Node Version Manager
if [[ -d "$HOME/.nvm" ]]; then
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
fi
