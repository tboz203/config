# last steps before handoff to user

pathmungex --replace --before PATH \
    ~/.maxar-bin \
    ~/.bin

if [[ ${_SHELL_INTERACTIVE-} ]]; then
    shopt -s failglob
fi

history -c && history -r
