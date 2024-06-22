#!/usr/bin/env bash
# shellcheck disable=2034

[[ ${_SHELL_INTERACTIVE-} ]] || return 0

if [[ ! -v BASH_COMPLETION_VERSINFO ]]; then
    # if bash completion hasn't been loaded yet, do that, and then return;
    # we expect that script to execute this script in turn, at which point the
    # remainder of this script is executed
    BASH_COMPLETION_USER_FILE=${BASH_SOURCE[0]}
    source /etc/profile.d/bash_completion.sh
    return
fi

((BASH_VERSINFO[0] < 5)) || shopt -s progcomp_alias

complete -F _command watch
complete -F _command viewpane

complete -C '/usr/local/bin/aws_completer' aws
