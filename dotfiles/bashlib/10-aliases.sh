# bashlib aliases

alias _log='echo >&2 "[.] ${FUNCNAME-${BASH_SOURCE-(main)}:$LINENO}"'

alias haveexe='type -P > /dev/null'
alias havecmd='type -t > /dev/null'
