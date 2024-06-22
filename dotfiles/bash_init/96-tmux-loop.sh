# connect to tmux

[[ ${_SHELL_INTERACTIVE-} ]] || return

# fix TERM for tmux
# if [[ $TERM != *256color && $COLORTERM == @(gnome-terminal|xfce4-terminal|truecolor) ]]; then
#     export TERM=xterm-256color
# elif [[ $COLORTERM == rxvt-xpm ]]; then
#     export TERM=rxvt-256color
# fi

if havebin tmux && [[ -v TURBO_MODE && ! -v TMUX ]]; then
    export _BASH_INIT_TMUX=1
    _if_verbose replace_exec
    exec tmux new-session -A -s main
fi
