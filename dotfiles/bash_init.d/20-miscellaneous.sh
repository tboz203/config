# miscellaneous bash profile cruft

export ANSIBLE_NOCOWS=1
export PIPENV_VENV_IN_PROJECT=1
export DOCKER_HIDE_LEGACY_COMMANDS=1
export DOCKER_BUILDKIT=1
setpath REQUESTS_CA_BUNDLE /etc/pki/ca-trust/extracted/openssl/ca-bundle.trust.crt || true

setpath BOOST_ROOT "$HOME/.local/boost_1_82_0"

setpath SDKMAN_DIR "$HOME/.sdkman"
sourcepath "$SDKMAN_DIR/bin/sdkman-init.sh"

# [ -z $SSH_AUTH_SOCK ] && eval $(ssh-agent -s) >/dev/null 2>&1

setpath M2_HOME "$HOME/.bootstrap/maven/default" || true
setpath JAVA_HOME "$HOME/.bootstrap/java/default" || true

setpath SSL_CERT_FILE /etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem || true

export PERL_MB_OPT="--install_base $HOME/perl5"
export PERL_MM_OPT="INSTALL_BASE=$HOME/perl5"

pathmungex PATH "$HOME/perl5/bin"
pathmungex -e -a PERL_LOCAL_LIB_ROOT "$HOME/perl5"
pathmungex -e PERL5LIB "$HOME/perl5/lib/perl5"

pathmungex -e PYTHONPATH "$HOME/.pymodules"

pathmungex -eb PKG_CONFIG_PATH \
    "$HOME/local/lib/pkgconfig" \
    "$HOME/local/lib64/pkgconfig" \
    "$HOME/local/share/pkgconfig" \
    /usr/local/lib/pkgconfig \
    /usr/local/lib64/pkgconfig \
    /usr/local/share/pkgconfig \
    /usr/lib/pkgconfig \
    /usr/lib64/pkgconfig \
    /usr/share/pkgconfig
