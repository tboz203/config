# ~/.profile/dircolors.sh

# If not running interactively, don't do anything
[[ $- == *i* ]] || return

command which dircolors &> /dev/null || return

if [[ -r ~/.dircolors ]]; then
    eval "$(dircolors -b ~/.dircolors)"
else
    eval "$(dircolors -b)"
fi
