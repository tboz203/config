#!/usr/bin/env bash
# shellcheck disable=2034

[[ ${_SHELL_INTERACTIVE-} || ! ${_BASHLIB_ROOT-} ]] || return 0

shopt -s progcomp

if ((BASH_VERSINFO[0] >= 5)); then
    shopt -s progcomp_alias
fi

setpath BASH_COMPLETION_USER_DIR ~/.bash_completion.d

if [[ ! -v BASH_COMPLETION_VERSINFO ]]; then
    source /etc/profile.d/bash_completion.sh
fi

complete -C aws_completer aws
complete -F _command viewpane
