# setup for cygwin

setpath -er CYGWIN_ROOT "/c/cygwin64" || return 0

pathmungex --replace PATH "$CYGWIN_ROOT/bin"
