# homebrew configuration

# [[ ${_SHELL_LOGIN-} ]] || return 0

# eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

# see ~/.homebrew/brew.env for other configuration

setpath -er HOMEBREW_PREFIX "/home/linuxbrew/.linuxbrew" || return 0

export HOMEBREW_CELLAR=$HOMEBREW_PREFIX/Cellar
export HOMEBREW_REPOSITORY=$HOMEBREW_PREFIX/Homebrew

pathmungex PATH "$HOMEBREW_PREFIX/bin" "$HOMEBREW_PREFIX/sbin" "$HOMEBREW_PREFIX/opt/coreutils/libexec/gnubin"

pathmungex -Eeb MANPATH "$HOMEBREW_PREFIX/share/man" ""
pathmungex -Eeb INFOPATH "$HOMEBREW_PREFIX/share/info"
pathmungex -Eeb PKG_CONFIG_PATH "$HOMEBREW_PREFIX"/{lib,lib64,share}/pkgconfig
pathmungex -Eeb XDG_DATA_DIRS "$HOMEBREW_PREFIX/share"

# # homebrew's version of bash completion is old and breaks things, but we do
# # want to try to load homebrew's installed completion scripts
# # pathmungex --before BASH_COMPLETION_PATHS "$HOMEBREW_PREFIX/etc/bash_completion"
# pathmungex BASH_COMPLETION_USER_DIR "$HOMEBREW_PREFIX/etc/bash_completion.d"

# remove linuxbrew from the current shell's environment
unbrew() {
    for pathvar in PATH MANPATH INFOPATH PKG_CONFIG_PATH XDG_DATA_DIRS; do
        pathmungex -D $pathvar "$HOMEBREW_PREFIX/*"
    done
}
