# source global bashrc

[[ ${_SHELL_INTERACTIVE-} ]] || return 0

[[ -f /etc/bashrc ]] || throw "bashrc missing"

# don't let bash completion run just yet; that's handled later
_reset_progcomp=$(shopt -p progcomp)
shopt -u progcomp

source /etc/bashrc

eval "$_reset_progcomp"
unset _reset_progcomp
