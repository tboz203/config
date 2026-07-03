# ensure PATH is populated

# [[ ! ${_BASH_INIT_PATHS_SET-} ]] || return 0
export _BASH_INIT_PATHS_SET=1

pathmungex --delete-matching PATH "/mnt/*" "/Docker/*"

pathmungex --replace PATH \
    ~/.local/bin \
    ~/.local/share/groovy/bin \
    ~/.local/share/node/bin \
    ~/.cargo/bin \
    ~/.poetry/bin \
    ~/.tgenv/bin \
    ~/.tfenv/bin \
    ~/.local/share/nvim/mason/bin \
    ~/.local/share/apache-maven-3.9.15/bin \
    ~/.local/share/maven-mvnd-1.0.6-linux-amd64/bin \
    ~/.local/share/groovy-5.0.5/bin \
    /usr/lib/cargo/bin \
    /usr/local/bin \
    /usr/bin
