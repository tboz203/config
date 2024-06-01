# ~/.profile/dircolors.sh

# If not running interactively, don't do anything
[[ $- == *i* ]] || return

haveexe dircolors || return

if [[ -r ~/.dircolors ]]; then
    eval "$(dircolors -b ~/.dircolors)"
else
    eval "$(dircolors -b)"
fi
