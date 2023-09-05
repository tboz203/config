#!/bin/sh
# ~/.profile: executed by the command interpreter for login shells.
# This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login
# exists.
# see /usr/share/doc/bash/examples/startup-files for examples.
# the files are located in the bash-doc package.

: top of profile

if ( fc-list | grep -iq powerline ) && [ -z "$SSH_CONNECTION" ] ; then
    export HAS_POWERLINE_FONTS=1
fi

export EDITOR=$HOME/.local/bin/vim
export PAGER=$HOME/.local/bin/less
export MAILTO=thomas.bozeman@cgifederal.com
export PYTHONSTARTUP=$HOME/.pythonrc.py
export REQUESTS_CA_BUNDLE=/etc/pki/ca-trust/extracted/openssl/ca-bundle.trust.crt
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

# include .bashrc if it exists
if [[ -f $HOME/.bashrc ]]; then
    . $HOME/.bashrc
fi

: end of profile
