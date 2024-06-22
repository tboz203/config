# homebrew configuration

# eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

[[ ${_SHELL_LOGIN-} ]] || return 0

# see ~/.homebrew/brew.env for other configuration

setpath -er HOMEBREW_PREFIX "/home/linuxbrew/.linuxbrew" || return 0

setpath -e HOMEBREW_CELLAR "$HOMEBREW_PREFIX/Cellar"
setpath -e HOMEBREW_REPOSITORY "$HOMEBREW_PREFIX/Homebrew"

pathmungex PATH "$HOMEBREW_PREFIX/bin" "$HOMEBREW_PREFIX/sbin"

pathmungex -Ee MANPATH "$HOMEBREW_PREFIX/share/man"
pathmungex -Ee INFOPATH "$HOMEBREW_PREFIX/share/info"

# homebrew's version of bash completion is old and breaks things, but we do
# want to try to load homebrew's installed completion scripts
# pathmungex --before BASH_COMPLETION_PATHS "$HOMEBREW_PREFIX/etc/bash_completion"
pathmungex BASH_COMPLETION_USER_DIR "$HOMEBREW_PREFIX/etc/bash_completion.d"
