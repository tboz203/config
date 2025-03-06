# last steps before handoff to user

cleanpath

pathmungex PATH --replace --before \
    ~/.maxar-bin \
    ~/.bin

if [[ ${_SHELL_INTERACTIVE-} ]]; then
    if [[ ${_SHELL_LOGIN-} && -f /etc/motd ]]; then
        cat /etc/motd
    fi
    shopt -s failglob
fi
