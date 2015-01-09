cat $0 | tee conf.out
./configure \
    --enable-fail-if-missing \
    --prefix=/usr \
    --enable-pythoninterp \
    --enable-rubyinterp \
    --enable-gui \
    --disable-netbeans \
    --with-features=huge \
    --with-python-config-dir=/usr/lib/python3.7/config-x86_64-linux-gnu \
    --with-x | tee -a conf.out
