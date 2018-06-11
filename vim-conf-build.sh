# https://github.com/Valloric/YouCompleteMe/wiki/Building-Vim-from-source
# sudo yum install ctags ruby-devel python36-devel ncurses-devel libX11-devel libxt-devel libXt-devel gtk3-devel
# git clone https://github.com/vim/vim && cd vim
cat $0 | tee conf.out
./configure \
    --enable-fail-if-missing \
    --prefix=$HOME/.local \
    --enable-python3interp \
    --enable-rubyinterp \
    --enable-gui \
    --with-features=huge \
    --with-python3-config-dir=/usr/lib64/python3.6/config-3.6m-x86_64-linux-gnu \
    --with-x \
    | tee -a conf.out
