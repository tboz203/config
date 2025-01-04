# # ensure pyenv isn't in path
# export PATH=$HOME/.local/bin:/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/usr/local/go/bin:$HOME/.nodenv/shims

# # specify our new gcc installation
# export CC=$(which gcc) CXX=$(which g++)

# pyenv shell system
# rbenv shell system

# using `--system-libclang` is "not recommended or supported", but the
# downloaded most-recent libclang seems to require a GLIBC that we don't have
# and can't use; all manner of things catch fire if I try to update that
./install.py --all --system-libclang
