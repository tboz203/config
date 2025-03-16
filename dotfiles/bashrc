#!/usr/bin/env bash
# bash init script

# order of operations:
# for interactive login shells:
#   /etc/profile
#     /etc/bash.bashrc (does basically nothing lol)
#     /etc/profile.d/*
#       /etc/profile.d/bash_completion.sh
#         ~/.config/bash_completion (<<<)
#         /usr/share/bash-completion/bash_completion (IF shopt -q progcomp; BIG)
#   ~/.bash_profile (or ~/.bash_login or ~/.profile; symlink to this file)
#
# interactive non-login shells:
#   /etc/bash.bashrc (does basically nothing lol)
#   ~/.bashrc (this file)
# non-interactive shells:
#   $BASH_ENV

function _bash_init {
    shopt -s checkhash
    shopt -s cdspell
    shopt -s dirspell
    shopt -s no_empty_cmd_completion

    # shopt -s extdebug

    # set -eu -o functrace errtrace
    # _BASHLIB_LOGLEVEL=debug
    # _BASHLIB_FLAGS=:replace_exec:stacktrace:

    local item
    for item in ~/.bash_init/*; do
        if [[ $item == *.sh ]]; then
            source "$item"
        else
            echo >&2 "[!] $FUNCNAME: Will not source file: $item"
        fi
    done
}

_bash_init

# ignore any crap installer scripts try to append to this file
return 0
