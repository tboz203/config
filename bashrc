# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc) for examples
# with modifications by tboz203
# vim: tw=119

# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

# If not running interactively, don't do anything
case $- in
    *i*) ;;
    *) return ;;
esac

pathmunge () {
    case ":${PATH}:" in
        *:"$1":*)
            ;;
        *)
            if [ ! -d "$1" ] ; then
                return
            fi
            if [ "$2" = "after" ] ; then
                PATH=$PATH:$1
            else
                PATH=$1:$PATH
            fi
    esac
}


# fix TERM for tmux (otherwise powerline doesn't work well)
if [[ $TERM != *256color && $COLORTERM == gnome-terminal || $COLORTERM == xfce4-terminal ]]; then
    export TERM=xterm-256color
elif [[ $COLORTERM == rxvt-xpm ]]; then
    export TERM=rxvt-256color
fi

# if has tmux and not nested, change process to new session
if [[ -x /usr/bin/tmux ]] && [[ -z "$TMUX" ]] && [[ -z $NO_TMUX ]]; then
    exec /usr/bin/tmux new-session -A -s main
fi

# ignore something-or-other (i think it's `ls` and `cd`?)
HISTCONTROL=ignoreboth
# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=
HISTFILESIZE=
HISTTIMEFORMAT="%h %d %H:%M:%S> "
HISTIGNORE="ls:la:lf:ll:l"

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# make less more friendly for non-text input files, see lesspipe(1)
[[ -x /usr/bin/lesspipe ]] && eval "$(SHELL=/bin/sh lesspipe)"

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
PS1="${u_color}\u${WHITE}@${GREEN}\h${WHITE} ${BLUE}\w ${reset}"
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
    # complete -c export
fi

# dircolors
if [[ -x /usr/bin/dircolors ]]; then
    if [[ -r ~/.dircolors ]]; then
        eval "$(dircolors -b ~/.dircolors)"
    else
        eval "$(dircolors -b)"
    fi
fi

vimwhich () { vim $( which $@ ); }
complete -c vimwhich
