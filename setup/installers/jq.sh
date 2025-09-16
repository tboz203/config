#!/usr/bin/env bash

set -eEuo pipefail
trap 'echo "err ($?) at ($BASH_SOURCE:$LINENO): $BASH_COMMAND"' ERR

os=$(uname -o)
if [[ $os != GNU/Linux ]]; then
    echo >&2 "[X] I can't help you: OS = $os"
    exit 1
fi

if type -P brew &> /dev/null; then
    exec brew install jq
fi

release=1.7.1
arch=$(uname -m)
release_url=https://github.com/jqlang/jq/releases/download/jq-$release/jq-linux

if [[ $arch == x86_64 ]]; then
    release_url+="-amd64"
else
    release_url+="-$arch"
fi

curl -fsSL "$release_url" -o ~/.local/bin/jq
chmod a+x ~/.local/bin/jq
