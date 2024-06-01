#!/bin/bash

# user completion file
# expects to be sourced by the tail end of bash_completion script

# bash completion is not exportable
[[ -v EXPORT_ONLY ]] && return

# If not running interactively, do nothing
[[ $- == *i* ]] || return

# have we been sourced too early?
[[ -v BASH_COMPLETION_VERSINFO ]] || return

# if something has overwritten the default completion loader, re-apply it
complete -p -D | grep -q _completion_loader || complete -D -F _completion_loader

complete -F _command watch
complete -F _command viewpane

complete -C '/usr/local/bin/aws_completer' aws

# outdated completion scripts in /etc/bash_completion.d prevents dynamic
# loading of new scripts
__load_completion git

# default _completion_loader throws warning messages for commands that are
# subdirectories in completion dirs
complete -F _minimal .

# ---

[[ ! -v BASH_COMPLETION_PATHS ]] && BASH_COMPLETION_PATHS=(~/.bash_completion.d/)

files=()

for path in "${BASH_COMPLETION_PATHS[@]}"; do
    if [[ -d $path && -r $path ]]; then
        files+=("$path"/*)
    elif [[ -r $path ]]; then
        files+=("$path")
    else
        echo >&2 "[!] bash completion paths: invalid path: $path"
    fi
done

for path in "${files[@]}"; do
    . "$path"
done

unset path files
