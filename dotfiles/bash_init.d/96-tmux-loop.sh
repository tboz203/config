# connect to tmux

# If not running interactively, do nothing
[[ $- == *i* ]] || return

# fix TERM for tmux
# if [[ $TERM != *256color && $COLORTERM == @(gnome-terminal|xfce4-terminal|truecolor) ]]; then
#     export TERM=xterm-256color
# elif [[ $COLORTERM == rxvt-xpm ]]; then
#     export TERM=rxvt-256color
# fi

# if we have tmux and we're not nested, change process to new session
if haveexe tmux && [[ ! -v TMUX && -v TURBO_MODE ]]; then
    exec tmux new-session -A -s main || {
        echo >&2 "[!] exec tmux failed"
        return 1
    }
fi
