# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# 2013/2/22 - Tommy Bozeman
# some slight modifications, mostly to PS1

# 2014-02-11 - Tommy Bozeman
# added autocd and ls PROMPT_COMMAND

HISTCONTROL=ignoreboth

# If not running interactively, don't do anything
[[ -z "$PS1" ]] && return

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000
HISTTIMEFORMAT="%h d %H:%M:%S> "
HISTIGNORE="ls:la:lf:ll:l"

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "$debian_chroot" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability
force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [[ -x /usr/bin/tput ]] && tput setaf 1 >& /dev/null; then
        # We have color support; assume it's compliant with Ecma-48
        # (ISO/IEC-6429). (Lack of such support is extremely rare, and such
        # a case would tend to support setf rather than setaf.)
        color_prompt=yes
    else
        color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
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
fi

u_color="$([[ "$EUID" -eq 0 ]] && echo "$RED" || echo "$GREEN")"
PS1="\[$reset\]$debian_chroot\[$u_color\]\u\[$WHITE\]@\[$GREEN\]\h\[$WHITE\]:"
PS1+="\[$BLUE\]\w\[$reset\]"
PS1+='$(__git_ps1 ":(%s)")\$ '
unset red RED green GREEN yellow YELLOW blue BLUE magenta MAGENTA cyan CYAN
unset white WHITE reset color_prompt force_color_prompt

# list files on directory change
PROMPT_COMMAND='[[ ${__new_wd:=$PWD} != $PWD ]] && ll; __new_wd=$PWD'

# set autocd: if command is a directory, cd to it
shopt -s autocd

# Alias definitions.
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# Function definitions.
if [ -f ~/.bash_functions ]; then
    . ~/.bash_functions
fi

# Enable programmable completion features.
if [ -f /etc/bash_completion ] && ! shopt -oq posix; then
    . /etc/bash_completion
fi

# dircolors
if [ -x /usr/bin/dircolors ]; then
    if [ -r ~/.dircolors ]; then
        eval "$(dircolors -b ~/.dircolors)"
    else
        eval "$(dircolors -b)"
    fi
fi

# # clear screen and list files after changing directory
# # this functionality is obsoleted by the PROMPT_COMMAND
# cd(){
#     if [ -n "$1" ]; then
#         builtin cd "$1"
#     else
#         builtin cd "$HOME"
#     fi

#     clear
#     ll
# }

if [ -f ~/.git-prompt ]; then
    . ~/.git-prompt
    GIT_PS1_SHOWDIRTYSTATE=1
    GIT_PS1_SHOWSTASHSTATE=1
    GIT_PS1_SHOWUNTRACKEDFILE=1
    GIT_PS1_SHOWCOLORHINTS=1
fi
