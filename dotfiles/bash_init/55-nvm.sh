# nvm

setpath -er NVM_DIR "$HOME/.nvm" || return 0

source "$NVM_DIR/nvm.sh"

function _load_nvm_completion {
    # prevent loops
    [[ -z ${COMP_WORDS[0]} ]] || complete -r "${COMP_WORDS[0]}"
    source "$NVM_DIR/bash_completion" && return 124
} && complete -F _load_nvm_completion nvm
