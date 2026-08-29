# nvm

# from homebrew install "Caveats" heading:
#
# >  Please note that upstream has asked us to make explicit managing
# >  nvm via Homebrew is unsupported by them and you should check any
# >  problems against the standard nvm install method prior to reporting.
# >
# >  You should create NVM's working directory if it doesn't exist:
# >    mkdir ~/.nvm
# >
# >  Add the following to your shell profile e.g. ~/.profile or ~/.zshrc:
# >    export NVM_DIR="$HOME/.nvm"
# >    [ -s "/home/linuxbrew/.linuxbrew/opt/nvm/nvm.sh" ] && \. "/home/linuxbrew/.linuxbrew/opt/nvm/nvm.sh"  # This loads nvm
# >    [ -s "/home/linuxbrew/.linuxbrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/home/linuxbrew/.linuxbrew/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion
# >
# >  You can set $NVM_DIR to any location, but leaving it unchanged from
# >  /opt/homebrew/Cellar/nvm/0.40.5 will destroy any nvm-installed Node installations
# >  upon upgrade/reinstall.


setpath -r NVM_INSTALL_DIR /home/linuxbrew/.linuxbrew/opt/nvm || return 0

export NVM_DIR="$HOME/.nvm"
mkdir -p "$NVM_DIR"

sourcepath "$NVM_INSTALL_DIR/nvm.sh"
sourcepath "$NVM_INSTALL_DIR/etc/bash_completion.d/nvm"

function _load_nvm_completion {
    # prevent loops
    [[ -z ${COMP_WORDS[0]} ]] || complete -r "${COMP_WORDS[0]}"
    source "$NVM_DIR/bash_completion" && return 124
} && complete -F _load_nvm_completion nvm

