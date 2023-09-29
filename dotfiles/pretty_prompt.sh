#!/bin/bash

pretty_prompt() {
    local red RED green GREEN yellow YELLOW blue BLUE magenta MAGENTA cyan CYAN
    local white WHITE reset color_prompt force_color_prompt

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

    if (( EUID == 0 )); then
        # root is red
        u_color="$RED"
    elif (( EUID < 1000 )); then
        # services are magenta
        u_color="$MAGENTA"
    else
        # everyone else (i.e. users) are green
        u_color="$GREEN"
    fi

    PS1="${u_color}\u${WHITE}@${GREEN}\h${WHITE} ${BLUE}\w ${reset}"

    # list files on directory change
    # PROMPT_COMMAND='[[ ${__new_wd:=$PWD} != $PWD ]] && ll; __new_wd=$PWD'

    if [[ -f ~/.git-prompt.sh ]]; then
        . ~/.git-prompt.sh
        GIT_PS1_SHOWDIRTYSTATE=1
        GIT_PS1_SHOWSTASHSTATE=1
        GIT_PS1_SHOWUNTRACKEDFILE=1
        GIT_PS1_SHOWCOLORHINTS=1
        PS1+='$(__git_ps1 ":(%s)")'
    fi

    PS1+="${WHITE}$ ${reset}"
}

[[ $- =~ i ]] && pretty_prompt
