#!/usr/bin/env bash
# shellcheck disable=2034

# bash completion is not exportable
[[ ! -v EXPORT_ONLY ]] || return

# If not running interactively, do nothing
[[ $- == *i* ]] || return

if [[ ! -v BASH_COMPLETION_VERSINFO ]]; then
    BASH_COMPLETION_USER_FILE=${BASH_SOURCE[0]}
    source "$LOCAL_BASH_COMPLETION"
    return
fi

# _source_bash_completion_paths()
# {
#     local -a pathlist files
#     from_list pathlist "$BASH_COMPLETION_PATHS"
#
#     # flatten our path list
#     local path
#     for path in "${pathlist[@]}"; do
#         if [[ -d $path && -r $path ]]; then
#             files+=("$path"/*)
#         elif [[ -r $path ]]; then
#             files+=("$path")
#         else
#             verbose "[!] invalid bash completion path: $path"
#         fi
#     done
#
#     _debug_var pathlist files
#
#     # source each item
#     for path in "${files[@]}"; do
#         # verbose "# sourcing bash completion script $path"
#         . "$path"
#     done
# }

# shopt -s progcomp
[[ ${BASH_VERSINFO[0]} -ge 5 ]] && shopt -s progcomp_alias

# pathmungex --before --replace BASH_COMPLETION_PATHS "$LOCAL_BASH_COMPLETION"
# pathmungex --after --replace BASH_COMPLETION_PATHS ~/.bash_completion.d/

# _source_bash_completion_paths

# # if something has overwritten the default completion loader, re-apply it
# complete -p -D | grep -q _completion_loader || complete -D -F _completion_loader

complete -F _command watch
complete -F _command viewpane

complete -C '/usr/local/bin/aws_completer' aws

# outdated completion scripts in /etc/bash_completion.d prevents dynamic
# loading of new scripts
# __load_completion git

# # default _completion_loader throws warning messages for commands that are
# # subdirectories in completion dirs
# complete -F _minimal .
