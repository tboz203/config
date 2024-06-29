# .bash_aliases
# vim: ft=bash

# expand aliases even if not interactive
# (note that we only define a handful of aliases when non-interactive)
shopt -s expand_aliases

alias rmf='rm -rf'
alias make='make -j $(nproc)'

alias xargs='xargs -r '

# some aliases for date in a sortable format
alias day='date +%Y-%m-%d'
alias full='date "+%Y.%m.%d-%H.%M.%S"'

[[ ${_SHELL_INTERACTIVE-} ]] || return 0

alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# make sure `diff` *has* color before trying to use it
if [[ $(diff --help 2>&1) == *'--color'* ]]; then
    alias diff='diff --color=auto'
fi

alias tree='tree -phugs -C --metafirst --dirsfirst'
if [[ $(tree --help 2>&1) == *'--gitignore'* ]]; then
    BASH_ALIASES['tree']+=' --gitignore'
fi

alias ls='ls --color=auto --ignore-backups --group-directories-first --sort=version'
alias ll='ls -lhF'
alias la='ls -A'
alias lla='ll -A'
alias lt='ls --sort=time'
alias llt='ll --sort=time'
alias l.='la -I "[^.]*"'
alias ll.='lla -I "[^.]*"'
alias l='ls -CF'
alias lf='ll -S'

alias files='fd . -t f'

# alias vim='vim -p'
alias vim='nvim'
# alias view='view -p'
alias view='nvim -R'
alias nv=nvim
alias nvdiff='nv -d'
alias nvimdiff=nvdiff

# alias cat=bat

# common misspellings
alias sl=ls
alias s=ls
alias fl=lf
alias f=lf
alias ivm=vim
alias vmi=vim
alias cdd=cd
alias dfn=dnf
alias qgit=git

alias dfx='df -h -t xfs'

# make some basic commands default to verbose, interactive, and recursive (if
# not already)
alias mv='mv -vi'
alias cp='cp -vri'
alias rm='rm -vI --one-file-system'

# default flags
# alias tidy='tidy -f /dev/null -iqmw'
# alias astyle='astyle -sajcn'
# alias find='find 2>/dev/null'
alias nl='nl -ba'
alias figlet='figlet -t'
alias ps='ps -H'
alias df='df -h'
alias xclip='xclip -selection clipboard'
alias http='http --ignore-stdin'
alias ncdu='ncdu --exclude-caches --exclude=node_modules --exclude=cache --exclude=.cache --exclude=venv --exclude=tmp'

alias vimrc='vim ~/config/dotfiles/vimrc'
alias bashrc='nv ~/config/dotfiles/{bashrc,bash_init/1?-*.sh}'
alias aliases='nv ~/config/dotfiles/bash_init/*aliases*'
alias bashlib='nv ~/config/dotfiles/bashlib{.sh,/*}'
alias bash_init='nv ~/config/dotfiles/{bashrc,bashlib{.sh,/*},bash_init/*}'
alias nvrc='nv ~/config/configfiles/nvim/lua/{plugins/core.lua,config/{lazy,options,keymaps}.lua}'
alias nvconfig='nv ~/config/configfiles/nvim/lua/{plugins,config}/*.lua'
alias nvimrc=nvrc

# alias docker-prune='docker system prune -f --volumes'
alias docker-prune='docker container prune -f && docker volume prune -f && docker image prune -f && docker network prune -f'
alias docker-halt='docker container ls -a --format "{{.Names}}" | xargs -r docker container rm -f'
alias docker-scrub='docker system prune -f --all --volumes'
alias docker-purge='docker-halt && docker-scrub'

alias open='gio open'
alias py='python'
alias ipy='ipython'
alias hd='hexdump -C'
# alias listening='lsof -i -s TCP:Listen'
# attempting to sort by listening address; not 100% effective
# alias ports='sudo ss -tlnp | ( sed -u 1q ; sort -k 4)'

alias loud='BASH_ENV=~/.bash_loud '

# become root, but with all my bells and whistles (not well tested)
alias super='sudo env HOME=$HOME /usr/local/bin/bash --login -i'

alias help2man='help2man -N -L $LC_ALL'

# make aliases of the form `...=../..`, `....=../../..`, etc
# these are most useful with `shopt -s autocd`
pattern="..=.."
for _ in {1..20}; do
    pattern=".${pattern}/.."
    eval alias $pattern
done
unset pattern
