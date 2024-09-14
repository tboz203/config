# last steps before handoff to user

pathmungex --before PATH \
    ~/.maxar-bin \
    ~/.bin

if [[ ${_SHELL_INTERACTIVE-} ]]; then
    shopt -s failglob
fi
