#!/bin/bash

# If not running interactively, don't do anything
[[ $- == *i* ]] || return

haveexe thefuck || return

function ugh()
{
    TF_PYTHONIOENCODING=$PYTHONIOENCODING
    export TF_SHELL=bash
    export TF_ALIAS=ugh
    export TF_SHELL_ALIASES=$(alias)
    export TF_HISTORY=$(fc -ln -10)
    export PYTHONIOENCODING=utf-8
    TF_CMD=$(
        thefuck THEFUCK_ARGUMENT_PLACEHOLDER "$@"
    ) && eval "$TF_CMD"
    unset TF_HISTORY
    export PYTHONIOENCODING=$TF_PYTHONIOENCODING
    history -s $TF_CMD
}
