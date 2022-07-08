# # ensure pyenv isn't in path
# export PATH=$HOME/.local/bin:/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/usr/local/go/bin:$HOME/.nodenv/shims

# # specify our new gcc installation
# export CC=$(which gcc) CXX=$(which g++)

pyenv shell system

./install.py --all
