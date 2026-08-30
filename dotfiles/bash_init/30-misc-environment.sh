# assorted environment variables

export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

# --------------------

# export DOCKER_HIDE_LEGACY_COMMANDS=1
export DOCKER_BUILDKIT=1
export COMPOSE_BAKE=1
export NODE_NO_WARNINGS=1

export PYTHONDONTWRITEBYTECODE=1
setpath -e PYTHONSTARTUP ~/.pythonrc.py

# [ -z $SSH_AUTH_SOCK ] && eval $(ssh-agent -s) >/dev/null 2>&1

# # on Debian/Ubuntu:
# setpath -e SSL_CERT_FILE /etc/ssl/certs/ca-certificates.crt
# # on RHEL/CentOS:
# setpath -e SSL_CERT_FILE /etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem
#
# setpath -e CURL_CA_BUNDLE "${SSL_CERT_FILE-}"
# setpath -e REQUESTS_CA_BUNDLE "${SSL_CERT_FILE-}"
# setpath -e GIT_SSL_CAINFO "${SSL_CERT_FILE-}"

pathmungex -e PYTHONPATH ~/.pymodules

pathmungex -er PKG_CONFIG_PATH {~/.local,/usr/local,/usr}/{lib,lib64,share}/pkgconfig

setpath -e RIPGREP_CONFIG_PATH ~/.ripgreprc

# --------------------

havebin wslview && export BROWSER=wslview

export EDITOR=nvim
export PAGER=less

# export LESS="-SRi"
export LESS="-SRFi"
(less --help |& grep -q "mouse") && LESS+=" --mouse --wheel-lines=3"
export LESSCHARSET=utf-8
