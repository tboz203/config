# .bash_aliases
# vim: ft=bash

# expand aliases even if not interactive
shopt -s expand_aliases

alias rmf='rm -rf'
alias xargs='xargs -r '
alias day='date +%Y-%m-%d'
alias full='date "+%Y.%m.%d-%H.%M.%S"'

[[ ${_SHELL_INTERACTIVE-} ]] || return 0

# common
#--------------------

alias ls='ls --color=auto --ignore-backups --group-directories-first --sort=version --ignore="NTUSER*" --ignore="ntuser*"'
alias ll='ls -lhF'
alias la='ls -A'
alias lla='ll -A'
# alias lt='ls --sort=time'
# alias llt='ll --sort=time'
alias lt='tree -pugshD -l --metafirst --dirsfirst --noreport --sort=version --filelimit=50'
if [[ $(tree --help 2>&1) == *'--gitignore'* ]]; then
    BASH_ALIASES['lt']+=' --gitignore'
fi
alias lta='lt -a'
alias l.='la -I "[^.]*"'
alias ll.='lla -I "[^.]*"'
alias l='ls -CF'
alias lf='ll -S'

alias vim='vim -p'
# alias vim='nvim'
alias view='view -p'
# alias view='nvim -R'
alias nv=nvim
alias nvdiff='nv -d'
alias nvimdiff=nvdiff

# default flags
# --------------------

alias mv='mv -vi'
alias cp='cp -vri'
alias rm='rm -vI --one-file-system'

alias grep='grep --color=auto'
alias fgrep='grep -F'
alias egrep='grep -E'
alias rgrep='grep -r'

if [[ $(diff --help 2>&1) == *'--color'* ]]; then
    alias diff='diff --color=auto'
fi

# alias tidy='tidy -f /dev/null -iqmw'
# alias astyle='astyle -sajcn'
alias nl='nl -ba'
alias figlet='figlet -t'
alias ps='ps -H'
alias df='df -h'
alias xclip='xclip -selection clipboard'
alias http='http --ignore-stdin'
alias ncdu='ncdu --exclude-caches --exclude=node_modules --exclude=cache --exclude=.cache --exclude=venv --exclude=tmp'
alias help2man='help2man -N -L $LC_ALL'
alias info='info --vi-keys'

# editing rc files
# --------------------

alias vimrc='vim ~/config/dotfiles/vimrc'
alias bashrc='nv ~/config/dotfiles/{bashrc,bash_init/1?-*.sh}'
alias aliases='nv ~/config/dotfiles/bash_init/*aliases*'
alias bashlib='nv ~/config/dotfiles/bashlib{.sh,/*}'
alias bash_init='nv ~/config/dotfiles/{bashrc,bashlib{.sh,/*},bash_init/*}'
alias nvrc='nv ~/config/configfiles/nvim/lua/{plugins/core.lua,config/{lazy,options,keymaps}.lua}'
alias nvconfig='nv ~/config/configfiles/nvim/lua/{plugins,config}/*.lua'
alias nvimrc=nvrc

# misspellings
# --------------------

alias sl=ls
alias s=ls
alias fl=lf
alias ivm=vim
alias vmi=vim
alias cdd=cd
alias dfn=dnf
alias qgit=git
alias vn=nv

# abbreviations & remappings
# --------------------

# alias cat=bat

alias py='python'
alias ipy='ipython'
alias hd='hexdump -C'

# new creations
# --------------------

# alias docker-prune='docker system prune -f --volumes'
alias docker-prune='docker container prune -f && docker volume prune -f && docker image prune -f && docker network prune -f'
alias docker-halt='docker container ls -a --format "{{.Names}}" | xargs -r docker container rm -f'
alias docker-scrub='docker system prune -f --all --volumes'
alias docker-purge='docker-halt && docker-scrub'

alias dfx='df -h -t xfs'
alias files='fd . -t f'
alias open='gio open'
# alias listening='lsof -i -s TCP:Listen'
# attempting to sort by listening address; not 100% effective
# alias ports='sudo ss -tlnp | ( sed -u 1q ; sort -k 4)'

alias super='sudo env HOME=$HOME /usr/local/bin/bash --login -i'

alias open='explorer.exe'

# meta-commands
# --------------------

alias loud='BASH_ENV=~/.bash_loud '

# dynamic
# --------------------

# make aliases of the form `...=../..`, `....=../../..`, etc
# these are most useful with `shopt -s autocd`
pattern="..=.."
for _ in {1..20}; do
    pattern=".${pattern}/.."
    eval alias $pattern
done
unset pattern
