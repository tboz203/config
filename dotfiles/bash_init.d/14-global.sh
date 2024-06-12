# source global bashrc

needs-restarting()
{
    # mask this slow script unless we're interactive
    [[ $- == *i* ]] || return 0
    command "${FUNCNAME[0]}" "$@"
}

if [[ -f /etc/bashrc ]]; then
    source /etc/bashrc
fi
