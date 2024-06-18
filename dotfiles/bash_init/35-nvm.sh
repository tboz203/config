# nvm

setpath NVM_DIR "$HOME/.nvm" || return 0

source "$NVM_DIR/nvm.sh"
# pathmungex BASH_COMPLETION_PATHS "$NVM_DIR/bash_completion"
pathmungex BASH_COMPLETION_USER_DIR "$NVM_DIR/bash_completion"
