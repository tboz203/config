# ensure PATH is populated

[[ ! ${_BASH_INIT_PATHS_SET-} ]] || return 0
export _BASH_INIT_PATHS_SET=1

cleanpath

pathmungex --replace PATH \
    ~/.local/bin \
    ~/.local/share/go/bin \
    ~/.local/share/groovy/bin \
    ~/.local/share/node/bin \
    ~/.cargo/bin \
    ~/.poetry/bin \
    ~/.tgenv/bin \
    ~/.tfenv/bin \
    ~/go/bin \
    ~/workspace/maxar/dodev \
    /usr/local/go/bin \
    /usr/local/bin \
    /usr/bin

pathmungex --after PATH \
    ~/.local/share/idea/bin \
    ~/.local/share/Postman \
    ~/.local/share/pycharm/bin \
    ~/.local/share/flyway \
    ~/.local/share/jdt-language-server/bin \
    ~/.local/share/plantuml \
    ~/.bootstrap/bin \
    ~/.bootstrap/java/default/bin \
    ~/.bootstrap/maven/default/bin \
    ~/.bootstrap/gradle/default/bin \
    ~/.bootstrap/miniconda/bin \
    /usr/pgsql-12/bin
