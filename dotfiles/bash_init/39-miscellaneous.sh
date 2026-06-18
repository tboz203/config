# miscellaneous bash profile cruft

# [[ ${_SHELL_LOGIN-} ]] || return 0

export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export EDITOR=nvim
export PAGER=less

# export DOCKER_HIDE_LEGACY_COMMANDS=1
export DOCKER_BUILDKIT=1
export COMPOSE_BAKE=1
export NODE_NO_WARNINGS=1

# export LESS="-SRi"
export LESS="-SRFi"
(less --help |& grep -q "mouse") && LESS+=" --mouse --wheel-lines=3"
export LESSCHARSET=utf-8

export PYTHONDONTWRITEBYTECODE=1
setpath -e PYTHONSTARTUP ~/.pythonrc.py

# [ -z $SSH_AUTH_SOCK ] && eval $(ssh-agent -s) >/dev/null 2>&1

setpath -e M2_HOME ~/.bootstrap/maven/default

# on Debian/Ubuntu:
setpath -e SSL_CERT_FILE /etc/ssl/certs/ca-certificates.crt
# on RHEL/CentOS:
setpath -e SSL_CERT_FILE /etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem

setpath -e CURL_CA_BUNDLE "${SSL_CERT_FILE-}"
setpath -e REQUESTS_CA_BUNDLE "${SSL_CERT_FILE-}"
setpath -e GIT_SSL_CAINFO "${SSL_CERT_FILE-}"

pathmungex -e PYTHONPATH ~/.pymodules

pathmungex -er PKG_CONFIG_PATH {~/.local,/usr/local,/usr}/{lib,lib64,share}/pkgconfig

setpath -e RIPGREP_CONFIG_PATH ~/.ripgreprc

# setpath -e JAVA_HOME /usr/lib/jvm/java-17-amazon-corretto
setpath -e JAVA_HOME /usr/lib/jvm/java-21-amazon-corretto
# setpath -e JAVA_HOME /usr/lib/jvm/java-25-amazon-corretto

export AWS_DEFAULT_PROFILE=ccc-lab
export AWS_DEFAULT_REGION=us-east-1

# havebin tofu && TG_TF_PATH=$(type -P tofu)
export TF_LOG=info
# set a much bigger timeout for tofu/terraform provider plugin downloads
export TF_REGISTRY_CLIENT_TIMEOUT=60

havebin wslview && export BROWSER=wslview
