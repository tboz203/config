# bashlib aliases
# shellcheck disable=2016,2139

alias print='printf "%s"'
alias println='printf "%s\n"'

# declare -g _WHERE='${FUNCNAME:-${BASH_SOURCE:-main}:$LINENO}'
declare -g _WHERE='$( [[ ${FUNCNAME-} && $FUNCNAME != source ]] && print "$FUNCNAME" || print "${BASH_SOURCE-main}:$LINENO" )'

alias _log="echo >&2 \"[.] ${_WHERE}:\""
alias _warn="echo >&2 \"[!] ${_WHERE}:\""
alias _err="echo >&2 \"[X] ${_WHERE}:\""

# silently check for a binary in the path
alias havebin='type > /dev/null -P'
# silently check for a command (i.e. a binary, function, builtin, or alias)
alias havecmd='type > /dev/null -t'

# print an error message & return 1
# usage: throw MESSAGE
# shellcheck disable=2154  # "message is referenced but not assigned" wrong
alias throw='{ local __message ; read -r __message ; _err "$__message" ; return 1 ; } <<<'

alias pause='{ read -rp "[press enter to continue] " || return $? ; }'
