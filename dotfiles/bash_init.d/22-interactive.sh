# If not running interactively, don't do anything
[[ $- == *i* ]] || return

# number one: complain
if [[ ${BASH_VERSINFO[0]} -lt 5 ]]; then
    echo >&2 "Hi! go update your bash please..."
fi

export LESS="-SRi"
(less --help |& grep -q "mouse") && LESS+=" --mouse --wheel-lines=3"
export LESSCHARSET=utf-8

[[ -e $HOME/.pythonrc.py ]] && export PYTHONSTARTUP=$HOME/.pythonrc.py

# if programmable completion wasn't activated by /etc/bashrc
# (or if we disabled it in ~/.config/bash_completion),
# re-enable it here
if ! shopt -q progcomp && [[ -r $LOCAL_BASH_COMPLETION ]]; then
    shopt -s progcomp
    [[ ${BASH_VERSINFO[0]} -ge 5 ]] && shopt -s progcomp_alias
    . "$LOCAL_BASH_COMPLETION"
fi

# don't save duplicate commands or commands starting with spaces in bash history
HISTCONTROL=ignoreboth
# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
# bash 4.2 doesn't seem to like negative values here...
# HISTSIZE="-1"
# HISTFILESIZE="-1"
HISTSIZE=$((2 ** 20))
HISTFILESIZE=$HISTSIZE
HISTIGNORE="ls:la:lf:ll:l"
# HISTTIMEFORMAT="%h %d %H:%M:%S> "
HISTTIMEFORMAT="%Y-%m-%d %H:%M:%S> "

if [[ $SUDO_USER ]]; then
    HISTFILE=/root/.bash_history.${SUDO_USER}
    history -c
    history -r
fi

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# use a specific key for rsync over ssh
export RSYNC_RSH="ssh -i $HOME/.ssh/rsync_key"

# set autocd: if command is a directory, cd to it
shopt -s autocd
# set recursive globbing w/ "**"
shopt -s globstar
# I wanna set this, but it seems like it would probably break things...
# shopt -s nocaseglob
# if any command in a pipeline fails, the pipeline should be considered to have failed
shopt -so pipefail
#
# these have been written to disk in order to reduce bash startup time. the
# bash completion ones are in ~/.local/share/bash-completion/completions and
# are lazily loaded at first use

haveexe kubectl && eval "$(kubectl completion bash)"
haveexe helm && eval "$(helm completion bash)"
haveexe kind && eval "$(kind completion bash)"
# haveexe poetry && eval "$(poetry completions bash)"
# haveexe pipenv && eval "$(_PIPENV_COMPLETE=bash_source pipenv)"
# haveexe oc && eval "$(oc completion bash)"
# haveexe yq && eval "$(yq shell-completion bash)"

# When set to "1" suggest all commands, including plumbing commands
# which are hidden by default (e.g. "cat-file" on "git ca<TAB>").
export GIT_COMPLETION_SHOW_ALL_COMMANDS=1
# When set to "1" suggest all options, including options which are
# typically hidden (e.g. '--allow-empty' for 'git commit').
export GIT_COMPLETION_SHOW_ALL=1

export GIT_PS1_SHOWDIRTYSTATE=1
export GIT_PS1_SHOWSTASHSTATE=1
export GIT_PS1_SHOWUNTRACKEDFILES=1
export GIT_PS1_SHOWUPSTREAM=auto
# export GIT_PS1_COMPRESSSPARSESTATE=1
# export GIT_PS1_OMITSPARSESTATE=1
export GIT_PS1_SHOWCONFLICTSTATE=1
export GIT_PS1_DESCRIBE_STYLE=branch
export GIT_PS1_SHOWCOLORHINTS=1
export GIT_PS1_HIDE_IF_PWD_IGNORED=1

# turn on every option listed in
# /usr/local/share/bash-completion/completions/docker
export DOCKER_COMPLETION_SHOW_CONFIG_IDS=yes
export DOCKER_COMPLETION_SHOW_CONTAINER_IDS=yes
export DOCKER_COMPLETION_SHOW_NETWORK_IDS=yes
export DOCKER_COMPLETION_SHOW_NODE_IDS=yes
export DOCKER_COMPLETION_SHOW_PLUGIN_IDS=yes
export DOCKER_COMPLETION_SHOW_SECRET_IDS=yes
export DOCKER_COMPLETION_SHOW_SERVICE_IDS=yes

PS1='\[\e[1;33m\]\u@\h \w \$ \[\e[0m\]'
sourcepath ~/.pretty_prompt.sh
