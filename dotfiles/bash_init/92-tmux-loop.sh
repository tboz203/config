# connect to tmux

[[ ${_SHELL_EXEC_TMUX-} ]] || return 0

# fix TERM for tmux
# if [[ $TERM != *256color && $COLORTERM == @(gnome-terminal|xfce4-terminal|truecolor) ]]; then
#     export TERM=xterm-256color
# elif [[ $COLORTERM == rxvt-xpm ]]; then
#     export TERM=rxvt-256color
# fi

_if_verbose replace_exec
exec tmux new-session -A -s main
