# miscellaneous bash profile cruft

[[ ${_SHELL_LOGIN-} ]] || return 0

export MAILTO=thomas.bozeman@cgifederal.com
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export EDITOR=nvim
export PAGER=less

export ANSIBLE_NOCOWS=1
export PIPENV_VENV_IN_PROJECT=1
export DOCKER_HIDE_LEGACY_COMMANDS=1
export DOCKER_BUILDKIT=1

export LESS="-SRi"
(less --help |& grep -q "mouse") && LESS+=" --mouse --wheel-lines=3"
export LESSCHARSET=utf-8

[[ ${SHELL-} != /bin/bash ]] || SHELL=/usr/local/bin/bash

setpath -e PYTHONSTARTUP ~/.pythonrc.py
setpath -e REQUESTS_CA_BUNDLE /etc/pki/ca-trust/extracted/openssl/ca-bundle.trust.crt
setpath -e BOOST_ROOT ~/.local/boost_1_82_0

if setpath -er SDKMAN_DIR ~/.sdkman; then
    sourcepath "$SDKMAN_DIR/bin/sdkman-init.sh"
fi

# [ -z $SSH_AUTH_SOCK ] && eval $(ssh-agent -s) >/dev/null 2>&1

setpath -e M2_HOME ~/.bootstrap/maven/default
setpath -e JAVA_HOME ~/.bootstrap/java/default

setpath -e SSL_CERT_FILE /etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem

export PERL_MB_OPT="--install_base $HOME/perl5"
export PERL_MM_OPT="INSTALL_BASE=$HOME/perl5"

pathmungex -a PATH ~/perl5/bin
pathmungex -e PERL5LIB ~/perl5/lib/perl5
setpath -e PERL_LOCAL_LIB_ROOT ~/perl5

pathmungex BASH_COMPLETION_USER_DIR ~/.local/share/bash-completion

pathmungex -e PYTHONPATH ~/.pymodules

pathmungex -eb PKG_CONFIG_PATH \
    ~/.local/lib/pkgconfig \
    ~/.local/lib64/pkgconfig \
    ~/.local/share/pkgconfig \
    /usr/local/lib/pkgconfig \
    /usr/local/lib64/pkgconfig \
    /usr/local/share/pkgconfig \
    /usr/lib/pkgconfig \
    /usr/lib64/pkgconfig \
    /usr/share/pkgconfig
