#!/bin/sh
# ~/.profile: executed by the command interpreter for login shells.
# This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login
# exists.
# see /usr/share/doc/bash/examples/startup-files for examples.
# the files are located in the bash-doc package.

# the default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
umask 022

pathmunge () {
    case ":${PATH}:" in
        *:"$1":*)
            ;;
        *)
            if [ -d "$1" ] ; then
                if [ "$2" = "after" ] ; then
                    PATH=$PATH:$1
                else
                    PATH=$1:$PATH
                fi
	    fi
    esac
}

pathmunge /usr/sbin         after
pathmunge $HOME/.local/bin
pathmunge $HOME/.bin

# add a personal module directory for python
if [ -d "$HOME/.pymodules" ]; then
    export PYTHONPATH="$HOME/.pymodules:$PYTHONPATH"
fi

if ( fc-list | grep -iq powerline ) && [ -z "$SSH_CONNECTION" ] ; then
    export HAS_POWERLINE_FONTS=1
fi

export EDITOR=/usr/local/bin/vim
export PAGER="/usr/bin/less -SR"
export MAILTO=thomas.bozeman@cgifederal.com
export PYTHONSTARTUP=$HOME/.pythonrc.py
export REQUESTS_CA_BUNDLE=/etc/pki/ca-trust/extracted/openssl/ca-bundle.trust.crt
export ORACLE_HOME=/opt/apps/oracle/oracle12.1.0.2/product/12.1.0.2/client_1
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

if [ -d $HOME/.local/share/man ]; then
    export MANPATH=$HOME/.local/share/man:/usr/share/man
fi

# if running bash
if [ -n "$BASH_VERSION" ]; then
    # include .bashrc if it exists
    if [ -f "$HOME/.bashrc" ]; then
        . "$HOME/.bashrc"
    fi
fi

unset pathmunge
