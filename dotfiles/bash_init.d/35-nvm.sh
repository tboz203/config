# nvm

setpath NVM_DIR "$HOME/.nvm" || return 0

source "$NVM_DIR/nvm.sh"
pathmungex BASH_COMPLETION_FILES "$NVM_DIR/bash_completion"
