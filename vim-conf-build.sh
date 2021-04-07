# https://github.com/Valloric/YouCompleteMe/wiki/Building-Vim-from-source
# sudo yum install ctags ruby-devel python36-devel ncurses-devel libX11-devel libxt-devel libXt-devel gtk3-devel
# git clone https://github.com/vim/vim && cd vim
cat $0 | tee conf.out
./configure \
    --enable-fail-if-missing \
    --prefix=$HOME/.local \
    --enable-pythoninterp=yes \
    --enable-rubyinterp=yes \
    --enable-gui \
    --with-features=huge \
    --with-python-config-dir=/usr/lib64/python2.7/config \
    --with-x \
    | tee -a conf.out

    # --enable-python3interp=yes \
    # --with-python3-config-dir=/usr/lib64/python3.6/config-3.6m-x86_64-linux-gnu \

# have most recently had an issue where `./configure ... LDFLAGS="-rdynamic"` is required for particular python
# commands to work, notably `python3 import math`
