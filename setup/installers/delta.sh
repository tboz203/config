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

releases_url='https://api.github.com/repos/dandavison/delta/releases'

machine=$(uname --machine)
package_suffix=${machine}-unknown-linux-gnu.tar.gz
filter='.[] | select(.draft or .prerelease | not) | .assets[] | select(.name | test($suffix)) | .browser_download_url, halt'
download_url=$(
    curl -fsSL "$releases_url" |
        jq -r --arg suffix "$package_suffix" "$filter"
)

curl -fsSL "$download_url" | tar -C ~/.local/bin -xz --strip=1 --no-anchored delta
chmod a+x ~/.local/bin/delta
