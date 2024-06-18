#!/usr/bin/env bash
# bash init script
# vim: tw=119

shopt -s checkhash
shopt -s execfail
shopt -s expand_aliases

shopt -s extglob
shopt -s globstar
shopt -s nullglob

# I wanna set this, but it seems like it would probably break things...
# shopt -s nocaseglob

# these *do* break things :/
# shopt -s failglob
# set -o pipefail

if [[ ${BASH_VERSINFO[0]} -ge 5 ]]; then
    shopt -s globskipdots
fi

bash_init()
{
    declare -g _BASH_INIT_STARTED=1

    local item
    for item in ~/.bash_init/*; do
        source "$item"
    done
}

# don't run twice, and don't recurse
[[ ${_BASH_INIT_RUN-} ]] || bash_init
