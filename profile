# ~/.profile: executed by the command interpreter for login shells.
# This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login
# exists.
# see /usr/share/doc/bash/examples/startup-files for examples.
# the files are located in the bash-doc package.

# the default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
umask 027

export PATH="$PATH:/sbin:/usr/sbin"

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/.bin" ] ; then
    export PATH="$HOME/.bin:$HOME/.local/bin:$PATH"
fi

# add a personal module directory for python
if [ -d "$HOME/.pymodules" ]; then
    export PYTHONPATH="$HOME/.pymodules:$PYTHONPATH"
fi

if ( fc-list | grep -iq powerline ); then
    export HAS_POWERLINE_FONTS=1
fi

export EDITOR=/usr/bin/vim
# export PYTHONDONTWRITEBYTECODE=1

# if running bash
if [ -n "$BASH_VERSION" ]; then
    # include .bashrc if it exists
    if [ -f "$HOME/.bashrc" ]; then
    . "$HOME/.bashrc"
    fi
fi
