#!/usr/bin/env bash

function _load_builtins {
    [[ -d ~/.local/lib/bash_loadable_builtins ]] || return 0

    declare -ga _LOADED_BUILTINS

    local item name
    for item in ~/.local/lib/bash_loadable_builtins/*.so; do
        name=$(basename "$item" .so)
        enable -f "$item" "$name" &> /dev/null || continue
        _LOADED_BUILTINS+=("$name")
    done
}

_load_builtins
