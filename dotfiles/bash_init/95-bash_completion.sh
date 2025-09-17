#!/usr/bin/env bash
# shellcheck disable=2034

# order of operations:
#   /etc/profile
#     /etc/profile.d/*
#       /etc/profile.d/bash_completion.sh
#         ~/.config/bash_completion (<<<)
#         /usr/share/bash-completion/bash_completion (IF shopt -q progcomp; BIG)
#           ...
#   ~/.bash_profile
#     ...

# From /etc/profile.d/bash_completion.sh
#  (does nothing if BASH_COMPLETION_VERSINFO is defined)
#  ~/.config/bash_completion
#  /usr/share/bash-completion/bash_completion (IF shopt -q progcomp)

# From /usr/share/bash-completion/bash_completion:
#   (defines completion functions)
#   (defines loader function)
#   (installs loader hook)
#   BASH_COMPLETION_COMPAT_DIR/* (/etc/bash_completion.d)
#     ...
#   BASH_COMPLETION_USER_FILE (~/.bash_completion; IF != ${BASH_SOURCE[0]})
#     ...

# BASH_COMPLETION_USER_DIR:
#   used by __load_completion from /usr/share/bash-completion/bash_completion
#   defaults to ~/.local/share/bash-completion/completions
#   first directory searched for dynamic completions
#
# BASH_COMPLETION_USER_FILE:
#   used by /usr/share/bash-completion/bash_completion
#   defaults to ~/.bash_completion
#   BASH_COMPLETION_USER_FILE is sourced by /usr/share/bash-completion/bash_completion
#     unless /usr/share/bash-completion/bash_completion is being sourced by BASH_COMPLETION_USER_FILE

shopt -q progcomp && [[ ${_BASHLIB_ROOT-} ]] || return 0

if [[ ! ${BASH_COMPLETION_ROOT-} ]]; then
    if [[ -d /usr/local/share/bash-completion ]]; then
        BASH_COMPLETION_ROOT=/usr/local/share/bash-completion
    else
        BASH_COMPLETION_ROOT=/usr/share/bash-completion
    fi
fi

setpath BASH_COMPLETION_USER_DIR ~/.bash_completion.d

sourcepath "$BASH_COMPLETION_ROOT/bash_completion"

# ! type -P aws aws_completer &> /dev/null || complete -C aws_completer aws
#
# ! type -P viewpane &> /dev/null || complete -F _command viewpane
#
# pathmungex BASH_COMPLETION_LOAD_PATH \
#     "${BASH_COMPLETION_USER_DIR-$HOME/.bash_completion.d}" \
#     ~/.local/share/bash-completion/completions \
#     /usr/local/share/bash-completion/completions \
#     /usr/share/bash-completion/completions
#
# __load_completion() {
#     local cmd="${1##*/}"
#     [[ -n $cmd ]] || return 1
#
#     local backslash
#     if [[ $cmd == \\* ]]; then
#         cmd="${cmd:1}"
#         # If we already have a completion for the "real" command, use it
#         $(complete -p "$cmd" 2> /dev/null || echo false) "\\$cmd" && return 0
#         backslash=\\
#     fi
#
#     local -a dirs
#     from_list dirs "$BASH_COMPLETION_LOAD_PATH"
#
#     local dir compfile
#     for dir in "${dirs[@]}"; do
#         [[ -d $dir ]] || continue
#         for compfile in "$cmd" "$cmd.bash" "_$cmd"; do
#             compfile="$dir/$compfile"
#             # Avoid trying to source dirs; https://bugzilla.redhat.com/903540
#             if [[ -f $compfile ]] && . "$compfile" &> /dev/null; then
#                 [[ $backslash ]] && $(complete -p "$cmd") "\\$cmd"
#                 return 0
#             fi
#         done
#     done
#
#     # Look up simple "xspec" completions
#     [[ -v _xspecs[$cmd] ]] &&
#         complete -F _filedir_xspec "$cmd" "$backslash$cmd" && return 0
#
#     return 1
# }
