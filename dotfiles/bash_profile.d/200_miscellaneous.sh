# miscellaneous bash profile cruft

export ANSIBLE_NOCOWS=1
export REQUESTS_CA_BUNDLE=/etc/pki/ca-trust/extracted/openssl/ca-bundle.trust.crt
export PIPENV_VENV_IN_PROJECT=1
export DOCKER_HIDE_LEGACY_COMMANDS=1
export DOCKER_BUILDKIT=1

# [[ -x $HOME/.local/bin/vim ]] && export EDITOR=$HOME/.local/bin/vim
# [[ -x $HOME/.local/bin/less ]] && export PAGER=$HOME/.local/bin/less
[[ -d $HOME/.local/boost_1_82_0 ]] && export BOOST_ROOT=$HOME/.local/boost_1_82_0

export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh"

# [ -z $SSH_AUTH_SOCK ] && eval $(ssh-agent -s) >/dev/null 2>&1

# export M2_HOME="$HOME/.bootstrap/maven/default"
# export JAVA_HOME="$HOME/.bootstrap/java/default"

export SSL_CERT_FILE=/etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem

export PERL_MB_OPT="--install_base $HOME/perl5"
export PERL_MM_OPT="INSTALL_BASE=$HOME/perl5"
pathmungex PATH "$HOME/perl5/bin"
pathmungex -e -a PERL_LOCAL_LIB_ROOT "$HOME/perl5"
pathmungex -e PERL5LIB "$HOME/perl5/lib/perl5"

pathmungex -e PYTHONPATH "$HOME/.pymodules"

export PKG_CONFIG_PATH
pathmungex PKG_CONFIG_PATH /usr/share/pkgconfig
pathmungex PKG_CONFIG_PATH /usr/lib64/pkgconfig
pathmungex PKG_CONFIG_PATH /usr/lib/pkgconfig
pathmungex PKG_CONFIG_PATH /usr/local/share/pkgconfig
pathmungex PKG_CONFIG_PATH /usr/local/lib64/pkgconfig
pathmungex PKG_CONFIG_PATH /usr/local/lib/pkgconfig
pathmungex PKG_CONFIG_PATH "$HOME/local/share/pkgconfig"
pathmungex PKG_CONFIG_PATH "$HOME/local/lib64/pkgconfig"
pathmungex PKG_CONFIG_PATH "$HOME/local/lib/pkgconfig"
