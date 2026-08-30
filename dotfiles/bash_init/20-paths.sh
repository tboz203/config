# ensure PATH is populated

pathmungex --delete-matching PATH "/mnt/*" "/Docker/*"

pathmungex --replace PATH \
    ~/.bin \
    ~/.local/bin

pathmungex --replace PATH \
    ~/.local/share/groovy/bin \
    ~/.local/share/node/bin \
    ~/.cargo/bin \
    ~/.poetry/bin \
    ~/.tgenv/bin \
    ~/.tfenv/bin \
    ~/.local/share/nvim/mason/bin \
    /usr/lib/cargo/bin

# pathmungex --replace PATH \
#     ~/.local/bin \
#     ~/.local/share/groovy/bin \
#     ~/.local/share/node/bin \
#     ~/.cargo/bin \
#     ~/.poetry/bin \
#     ~/.tgenv/bin \
#     ~/.tfenv/bin \
#     ~/.local/share/nvim/mason/bin \
#     /usr/lib/cargo/bin \
#     /usr/local/bin \
#     /usr/bin
