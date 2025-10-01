# golang environment setup

return 0

havebin go || return 0

export GOPATH="$HOME/.local/opt/go"
mkdir -p "$GOPATH"

function _add_go_to_path {
    local gobin goroot

    pathmungex PATH /usr/local/go/bin /usr/lib/go/bin

    gobin=$(go env GOBIN)
    if [[ -z $gobin ]]; then
        gobin=$GOPATH/bin
    fi
    mkdir -p "$gobin"
    pathmungex PATH "$gobin"

    goroot=$(go env GOROOT)
    if [[ $goroot ]]; then
        pathmungex PATH "$goroot/bin"
    fi
}

_add_go_to_path
unset _add_gobin_to_path
