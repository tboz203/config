#!/usr/bin/env bash
# shellcheck disable=2034

[[ ${_SHELL_INTERACTIVE-} ]] || return 0

# export TZ=UTC
# export TZ='America/Chicago'

PS1='\[\e[1;33m\]\u \w \$ \[\e[0m\]'

# don't save duplicate commands or commands starting with spaces in bash history
HISTCONTROL=ignoreboth

# command history length in memory
HISTSIZE="-1"
# # bash 4.2 doesn't seem to like negative values here...
# HISTSIZE=$((2 ** 20))
# command history length on disk
# HISTFILESIZE="-1"
HISTFILESIZE=$HISTSIZE
HISTIGNORE="ls:la:ll:lt"
HISTTIMEFORMAT="%Y-%m-%d %H:%M:%S> "

if [[ -n ${SUDO_USER-} ]]; then
    HISTFILE=/root/.bash_history.${SUDO_USER}
    history -c && history -r
fi

[[ ${MAILCHECK-} ]] || MAILCHECK=60
pathmungex MAILPATH "${MAIL-/nowhere}" "/var/mail/$LOGNAME"

# check the window size after each command
shopt -s checkwinsize
# if command is a directory, cd to it
shopt -s autocd

# use a specific key for rsync over ssh
[[ -r ~/.ssh/rsync_key ]] && export RSYNC_RSH="ssh -i $HOME/.ssh/rsync_key"

if havebin dircolors; then
    if [[ -r ~/.dircolors ]]; then
        eval "$(dircolors -b ~/.dircolors)"
    else
        eval "$(dircolors -b)"
    fi
fi

# these have been written to disk in order to reduce bash startup time. the
# bash completion ones are in ~/.local/share/bash-completion/completions and
# are lazily loaded at first use

# havebin kubectl && eval "$(kubectl completion bash)"
# havebin helm && eval "$(helm completion bash)"
# havebin kind && eval "$(kind completion bash)"
# havebin poetry && eval "$(poetry completions bash)"
# havebin pipenv && eval "$(_PIPENV_COMPLETE=bash_source pipenv)"
# havebin oc && eval "$(oc completion bash)"
# havebin yq && eval "$(yq shell-completion bash)"

# When set to "1" suggest all commands, including plumbing commands
# which are hidden by default (e.g. "cat-file" on "git ca<TAB>").
GIT_COMPLETION_SHOW_ALL_COMMANDS=1
# When set to "1" suggest all options, including options which are
# typically hidden (e.g. '--allow-empty' for 'git commit').
GIT_COMPLETION_SHOW_ALL=1

GIT_PS1_SHOWDIRTYSTATE=1
GIT_PS1_SHOWSTASHSTATE=1
GIT_PS1_SHOWUNTRACKEDFILES=1
GIT_PS1_SHOWUPSTREAM=auto
# GIT_PS1_COMPRESSSPARSESTATE=1
# GIT_PS1_OMITSPARSESTATE=1
GIT_PS1_SHOWCONFLICTSTATE=1
GIT_PS1_DESCRIBE_STYLE=branch
GIT_PS1_SHOWCOLORHINTS=1
GIT_PS1_HIDE_IF_PWD_IGNORED=1

# turn on every option listed in
# /usr/local/share/bash-completion/completions/docker
DOCKER_COMPLETION_SHOW_CONFIG_IDS=yes
DOCKER_COMPLETION_SHOW_CONTAINER_IDS=yes
DOCKER_COMPLETION_SHOW_NETWORK_IDS=yes
DOCKER_COMPLETION_SHOW_NODE_IDS=yes
DOCKER_COMPLETION_SHOW_PLUGIN_IDS=yes
DOCKER_COMPLETION_SHOW_SECRET_IDS=yes
DOCKER_COMPLETION_SHOW_SERVICE_IDS=yes

# if MANPATH is set, it almost definitely doesn't have everything it needs to
# have, so make sure it starts with the null entry (which indicates the
# default MANPATH lookup algorithm)
pathmungex -brE MANPATH ""

# Set cursor shape:
# Blinking Block: echo -ne "\e[1 q"
# Steady Block: echo -ne "\e[2 q"
# Blinking Underline: echo -ne "\e[3 q"
# Steady Underline: echo -ne "\e[4 q"
# Blinking Bar (I-beam): echo -ne "\e[5 q"
# Steady Bar (I-beam): echo -ne "\e[6 q"

# set cursor to I-beam before & after each command
PROMPT_COMMAND="printf '\e[6 q'${PROMPT_COMMAND+;${PROMPT_COMMAND}}"
PS0="\e[6 q${PS0}"
