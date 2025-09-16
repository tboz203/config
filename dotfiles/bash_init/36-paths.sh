# ensure PATH is populated

[[ ! ${_BASH_INIT_PATHS_SET-} ]] || return 0
export _BASH_INIT_PATHS_SET=1

pathmungex --replace PATH \
    ~/.local/bin \
    ~/.local/share/groovy/bin \
    ~/.local/share/node/bin \
    ~/.cargo/bin \
    ~/.poetry/bin \
    ~/.tgenv/bin \
    ~/.tfenv/bin \
    /usr/lib/cargo/bin \
    /usr/local/bin \
    /usr/bin

pathmungex --delete-matching PATH '/mnt/c/*'
