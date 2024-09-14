# source global bashrc

[[ ${_SHELL_INTERACTIVE-} ]] || return 0

[[ -f /etc/bashrc ]] || throw "bashrc missing"

# don't let bash completion run just yet; that's handled later
shopt -u progcomp

withflags +eu source /etc/bashrc
