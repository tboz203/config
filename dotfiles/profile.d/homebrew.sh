# homebrew configuration

# eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

export HOMEBREW_PREFIX="/home/linuxbrew/.linuxbrew"
export HOMEBREW_CELLAR="$HOMEBREW_PREFIX/Cellar"
export HOMEBREW_REPOSITORY="$HOMEBREW_PREFIX/Homebrew"

pathmungex PATH "$HOMEBREW_PREFIX/sbin"
pathmungex PATH "$HOMEBREW_PREFIX/bin"

pathmungex MANPATH "$HOMEBREW_PREFIX/share/man"
pathmungex INFOPATH "$HOMEBREW_PREFIX/share/info"

pathmungex BASH_COMPLETION_DIRS "$HOMEBREW_PREFIX/etc/bash_completion.d"
