# homebrew configuration

# eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

setpath HOMEBREW_PREFIX "/home/linuxbrew/.linuxbrew" || return 0

setpath HOMEBREW_CELLAR "$HOMEBREW_PREFIX/Cellar"
setpath HOMEBREW_REPOSITORY "$HOMEBREW_PREFIX/Homebrew"

pathmungex PATH "$HOMEBREW_PREFIX/sbin" "$HOMEBREW_PREFIX/bin"

pathmungex MANPATH "$HOMEBREW_PREFIX/share/man"
pathmungex INFOPATH "$HOMEBREW_PREFIX/share/info"

# old & breaks things
# pathmungex --before BASH_COMPLETION_PATHS "$HOMEBREW_PREFIX/etc/bash_completion"
pathmungex --before BASH_COMPLETION_DIRS "$HOMEBREW_PREFIX/etc/bash_completion.d"

# handling periodic updates as a cron job
export HOMEBREW_NO_AUTO_UPDATE=1
