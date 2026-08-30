#!/usr/bin/env bash

set -ex

cd "$HOME"

sudo apt update && sudo apt upgrade -y
sudo apt install build-essential curl file git man procps python3 unzip vim zip

git clone https://github.com/tboz203/config ~/config
git clone https://github.com/tboz203/nvconfig ~/config/configfiles/nvim
git -C ~/config submodule update --init

python3 ~/config/install.py --relative-links --overwrite-conflicts

bash ~/config/setup/installers/homebrew.sh
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv bash)"
brew bundle
