# source global bashrc

# _debug_trace

# if we have our own installation of bash_completion, don't let
# /etc/profile.d/bash_completion.sh source the system installation
# LOCAL_BASH_COMPLETION=$HOME/.local/share/bash-completion/bash_completion
LOCAL_BASH_COMPLETION=/usr/local/share/bash-completion/bash_completion
[[ -r $LOCAL_BASH_COMPLETION ]] && shopt -u progcomp

[[ -f /etc/bashrc ]] && . /etc/bashrc
