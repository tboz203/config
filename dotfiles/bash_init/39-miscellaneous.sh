# miscellaneous bash profile cruft

# [[ ${_SHELL_LOGIN-} ]] || return 0

export MAILTO=thomas.bozeman@cgifederal.com
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export EDITOR=nvim
export PAGER=less

# export DOCKER_HIDE_LEGACY_COMMANDS=1
export DOCKER_BUILDKIT=1
export NODE_NO_WARNINGS=1

export LESS="-SRi"
if havebin less && [[ $(less --help 2>&1) == "*mouse*" ]]; then
    LESS+=" --mouse --wheel-lines=3"
fi
export LESSCHARSET=utf-8

setpath -e PYTHONSTARTUP ~/.pythonrc.py

# [ -z $SSH_AUTH_SOCK ] && eval $(ssh-agent -s) >/dev/null 2>&1

setpath -e M2_HOME ~/.bootstrap/maven/default

# setpath -e SSL_CERT_FILE /etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem
setpath -e SSL_CERT_FILE /etc/ssl/certs/ca-certificates.crt

pathmungex -e PYTHONPATH ~/.pymodules

pathmungex -er PKG_CONFIG_PATH {~/.local,/usr/local,/usr}/{lib,lib64,share}/pkgconfig

# ---

setpath -e SSL_CERT_FILE /etc/ssl/certs/ca-certificates.crt
