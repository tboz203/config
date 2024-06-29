#!/usr/bin/env bash
# shellcheck disable=2034

[[ ${_SHELL_INTERACTIVE-} ]] || return 0

shopt -s progcomp

if ((BASH_VERSINFO[0] >= 5)); then
    shopt -s progcomp_alias
fi

if [[ ! -v BASH_COMPLETION_VERSINFO ]]; then
    # if bash completion hasn't been loaded yet, do that, and then return;
    # we expect that script to execute this script in turn, at which point the
    # remainder of this script is executed
    BASH_COMPLETION_USER_FILE=${BASH_SOURCE[0]}
    source /etc/profile.d/bash_completion.sh
    return
fi

complete -C aws_completer aws
