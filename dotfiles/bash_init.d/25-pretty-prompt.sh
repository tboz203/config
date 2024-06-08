#!/usr/bin/env bash
# make a pretty PS1
# shellcheck disable=2034

pretty_prompt()
{
    local BLACK="\[\e[1;30m\]"
    local RED="\[\e[1;31m\]"
    local GREEN="\[\e[1;32m\]"
    local YELLOW="\[\e[1;33m\]"
    local BLUE="\[\e[1;34m\]"
    local MAGENTA="\[\e[1;35m\]"
    local CYAN="\[\e[1;36m\]"
    local WHITE="\[\e[1;37m\]"

    # local black="\[\e[0;30m\]"
    # local red="\[\e[0;31m\]"
    # local green="\[\e[0;32m\]"
    # local yellow="\[\e[0;33m\]"
    # local blue="\[\e[0;34m\]"
    # local magenta="\[\e[0;35m\]"
    # local cyan="\[\e[0;36m\]"
    # local white="\[\e[0;37m\]"

    local reset="\[\e[0m\]"

    local -a parts

    if ((EUID == 0)); then
        # superuser name in red
        parts+=("$RED" '\u')
    elif ((EUID < 1000)); then
        # services name in magenta
        parts+=("$MAGENTA" '\u')
    else
        # user name in green
        parts+=("$GREEN" '\u')
    fi

    if [[ -v SSH_CONNECTION ]]; then
        # bold white `@` and red hostname
        parts+=("$WHITE" '@' "$RED" '\h')
    fi

    parts+=(
        ' '
        # working directory (shortened in home directory) in blue
        "$BLUE" '\w '
        # hash if superuser, otherwise dollar sign
        "$WHITE" '\$ '
        "$reset"
    )

    read -r PS1 <<< "$(printf "%s" "${parts[@]}")"

    if havecmd __git_ps1; then
        # shellcheck disable=2016
        local git_ps1="$reset"'$(__git_ps1 ":(%s)")'
        PS1=${PS1/\\w/&$git_ps1}
    fi

    # list files on directory change
    # [[ -v PROMPT_COMMAND && $PROMPT_COMMAND != *; ]] && PROMPT_COMMAND+=';'
    # PROMPT_COMMAND+='[[ ${__old_wd:=$PWD} != $PWD ]] && ll; __old_wd=$PWD'
}

[[ $- =~ i ]] && pretty_prompt
