# ~/.profile/dircolors.sh

# If not running interactively, don't do anything
[[ $- == *i* ]] || return 0

haveexe dircolors || return 0

if [[ -r ~/.dircolors ]]; then
    eval "$(dircolors -b ~/.dircolors)"
else
    eval "$(dircolors -b)"
fi
