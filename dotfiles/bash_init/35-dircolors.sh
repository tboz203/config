# ~/.profile/dircolors.sh

[[ ${_SHELL_INTERACTIVE-} ]] || return 0

havebin dircolors || return 0

if [[ -r ~/.dircolors ]]; then
    eval "$(dircolors -b ~/.dircolors)"
else
    eval "$(dircolors -b)"
fi
