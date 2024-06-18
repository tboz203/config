# source global bashrc

needs-restarting()
{
    # mask this slow script unless we're interactive
    [[ $- == *i* ]] || return 0
    command "${FUNCNAME[0]}" "$@"
}

_state=${-//[^evux]/}
set +eux

if [[ -f /etc/bashrc ]]; then
    source /etc/bashrc
fi

set +eux ${_state+-$_state}
unset _state
