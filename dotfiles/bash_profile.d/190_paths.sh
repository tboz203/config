# ensure PATH is populated

# counter-intuitively, later lines will be higher in the path
pathmungex PATH "/usr/local/go/bin"

pathmungex PATH "$HOME/workspace/maxar/dodev"

pathmungex PATH "$HOME/.local/share/plantuml"
pathmungex PATH "$HOME/.local/share/jdt-language-server/bin"
pathmungex PATH "$HOME/.local/share/node/bin"
pathmungex PATH "$HOME/.local/share/flyway"
pathmungex PATH "$HOME/.local/share/pycharm/bin"
pathmungex PATH "$HOME/.local/share/Postman"
pathmungex PATH "$HOME/.local/share/idea/bin"
pathmungex PATH "$HOME/.local/share/groovy/bin"
pathmungex PATH "$HOME/.local/share/go/bin"
pathmungex PATH "$HOME/.local/bin"

pathmungex PATH "$HOME/go/bin"
pathmungex PATH "$HOME/.cargo/bin"
pathmungex PATH "$HOME/.poetry/bin"
pathmungex PATH "$HOME/.rbenv/bin"
pathmungex PATH "$HOME/.nodenv/bin"
pathmungex PATH "$HOME/.pyenv/bin"
pathmungex PATH "$HOME/.tfenv/bin"
pathmungex PATH "$HOME/.tgenv/bin"
pathmungex PATH "$HOME/.bin"
pathmungex PATH "$HOME/.maxar-bin"

pathmungex --after PATH "$HOME/.bootstrap/bin"
pathmungex --after PATH "$HOME/.bootstrap/java/default/bin"
pathmungex --after PATH "$HOME/.bootstrap/maven/default/bin"
pathmungex --after PATH "$HOME/.bootstrap/gradle/default/bin"
pathmungex --after PATH "$HOME/.bootstrap/miniconda/bin"

pathmungex --after PATH /usr/pgsql-12/bin
