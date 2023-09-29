#!/bin/bash

# put ~/.local libraries into the global shared library search path
# if this seems not-great, that's because it is!

set -euo pipefail
trap 'echo "err ($?) at ($BASH_SOURCE:$LINENO): $BASH_COMMAND"' ERR

user_conf="/etc/ld.so.conf.d/${USER}.conf"
user_libs=(
    "$HOME/.local/lib"
    "$HOME/.local/lib64"
)

# get sudo rights first
sudo echo here we go

if [[ ! -f $user_conf ]]; then
    for lib in "${user_libs[@]}"; do
        [[ -d $lib ]] || continue
        grep -q $lib $user_conf && continue
        # the variable expansion happens before handing off to the second bash
        # instance, so the single-quotes are okay
        sudo bash -c "echo '$lib' >> '$user_conf'"
    done
fi

sudo ldconfig
