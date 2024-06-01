# ensure PATH is populated

# _start_debug_trace

pathmungex PATH \
    "$HOME/.local/bin" \
    "$HOME/.local/share/go/bin" \
    "$HOME/.local/share/groovy/bin" \
    "$HOME/.local/share/node/bin" \
    "$HOME/.cargo/bin" \
    "$HOME/.poetry/bin" \
    "$HOME/go/bin" \
    "$HOME/workspace/maxar/dodev" \
    "/usr/local/go/bin"

pathmungex --before PATH \
    "$HOME/.maxar-bin" \
    "$HOME/.bin" \
    "$HOME/.tgenv/bin" \
    "$HOME/.tfenv/bin" \
    "$HOME/.pyenv/bin" \
    "$HOME/.nodenv/bin" \
    "$HOME/.rbenv/bin"

pathmungex --after PATH \
    "$HOME/.local/share/idea/bin" \
    "$HOME/.local/share/Postman" \
    "$HOME/.local/share/pycharm/bin" \
    "$HOME/.local/share/flyway" \
    "$HOME/.local/share/jdt-language-server/bin" \
    "$HOME/.local/share/plantuml" \
    "$HOME/.bootstrap/bin" \
    "$HOME/.bootstrap/java/default/bin" \
    "$HOME/.bootstrap/maven/default/bin" \
    "$HOME/.bootstrap/gradle/default/bin" \
    "$HOME/.bootstrap/miniconda/bin" \
    "/usr/pgsql-12/bin"
