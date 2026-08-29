# homebrew configuration
# see ~/.homebrew/brew.env for other configuration

# [[ ${_SHELL_LOGIN-} ]] || return 0

# eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

setpath -er HOMEBREW_PREFIX /home/linuxbrew/.linuxbrew || return 0

# export HOMEBREW_CELLAR=$HOMEBREW_PREFIX/Cellar
# export HOMEBREW_REPOSITORY=$HOMEBREW_PREFIX/Homebrew
export HOMEBREW_BUNDLE_FILE=$HOME/.homebrew/Brewfile

pathmungex -r PATH \
    "$HOMEBREW_PREFIX/bin" \
    "$HOMEBREW_PREFIX/sbin" \
    "$HOMEBREW_PREFIX/opt/coreutils/libexec/gnubin" \
    "$HOMEBREW_PREFIX/opt/postgresql@17/bin" \
    "$HOMEBREW_PREFIX/lib/ruby/gems/3.4.0/bin"

pathmungex -Eer MANPATH "$HOMEBREW_PREFIX/share/man" ""
pathmungex -Eer INFOPATH "$HOMEBREW_PREFIX/share/info"
pathmungex -Eer PKG_CONFIG_PATH "$HOMEBREW_PREFIX"/{lib,lib64,share}/pkgconfig
pathmungex -Eer XDG_DATA_DIRS "$HOMEBREW_PREFIX/share"

setpath BASH_COMPLETION_ROOT "$HOMEBREW_PREFIX/share/bash-completion"
pathmungex --before BASH_COMPLETION_LOAD_PATH "$HOMEBREW_PREFIX/share/bash-completion"

# remove linuxbrew from the current shell's environment
function unbrew {
    for pathvar in PATH MANPATH INFOPATH PKG_CONFIG_PATH XDG_DATA_DIRS; do
        pathmungex -D $pathvar "$HOMEBREW_PREFIX/*"
    done
}
