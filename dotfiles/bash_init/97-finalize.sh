# last steps before handoff to user

cleanpath

pathmungex PATH --replace --before \
    ~/.bin

# if /bin is a symlink to /usr/bin
if [[ -L /bin && ! -L /usr/bin && /bin -ef /usr/bin ]]; then
    # add /usr/bin to the path if it's missing and remove /bin
    pathmungex PATH /usr/bin
    pathmungex --delete PATH /bin
fi

# if we've been told to start tmux, then do so now
if [[ ${_SHELL_EXEC_TMUX-} ]]; then

    # fix TERM for tmux
    # if [[ $TERM != *256color && $COLORTERM == @(gnome-terminal|xfce4-terminal|truecolor) ]]; then
    #     export TERM=xterm-256color
    # elif [[ $COLORTERM == rxvt-xpm ]]; then
    #     export TERM=rxvt-256color
    # fi

    _if_verbose replace_exec

    exec tmux new-session -A -s main
fi

if [[ ${_SHELL_INTERACTIVE-} ]]; then
    if [[ ${_SHELL_LOGIN-} && -f /etc/motd ]]; then
        cat /etc/motd
    fi
    shopt -s failglob
fi

# -----
# commands requiring other things to already be on the path
# (need a better way to handle this...)

havebin mvnd && alias mvn='mvnd '
havebin wslview && alias open='wslview'
