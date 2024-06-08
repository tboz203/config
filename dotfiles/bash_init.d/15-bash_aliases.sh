# .bash_aliases
# vim: ft=bash

# expand aliases even if not interactive
# (note that we only define a handful of aliases when non-interactive)
shopt -s expand_aliases

alias rmf='rm -rf'
alias curl='curl -w "\n"'
alias cd='cd -P'
alias make='make -j $(nproc)'

alias xargs='xargs -r '

# check for an executable in the path
alias haveexe='type -P > /dev/null'
# check for any callable
alias havecmd='type -t > /dev/null'

# some aliases for date in a sortable format
alias day='date +%Y-%m-%d'
alias full='date "+%Y.%m.%d-%H.%M.%S"'

# print out all variables, even if not exported
# sh*llcheck sees `$item` being used, but not defined 🙄
# shellcheck disable=SC2154
# alias xenv='compgen -v | grep -v "^_" | sort | while read -r item; do declare -p $item ; done'

# If not running interactively, stop here
# ========================================
[[ $- == *i* ]] || return

# color aliases
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# make sure `diff` *has* color before trying to use it
diff --help 2>&1 | grep -q -- '--color' && alias diff='diff --color=auto'

alias tree='tree -phugs -C --metafirst --dirsfirst'
if tree --help 2>&1 | grep -q -- '--gitignore'; then
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
alias nvimdiff='nvim -d'
alias nvdiff=nvimdiff

alias cat=bat

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

# set some default flags
# alias tidy='tidy -f /dev/null -iqmw'
# alias astyle='astyle -sajcn'
# alias find='find 2>/dev/null'
alias nl='nl -ba'
alias figlet='figlet -t'
# alias rgrep='grep -r'
alias ps='ps -H'
alias df='df -h'
# alias du='du -shc'

alias vimrc='vim ~/.vimrc'
# alias gvimrc='gvim ~/.gvimrc'
alias bashrc='nv ~/.bashrc ~/.bash_init.d/[0-2]*'
alias aliases='nv ~/.bash_init.d/*alias*'
alias functions='nv ~/.bash_init.d/*function*'
alias nvconfig='nv ~/.config/nvim/lua/config/lazy.lua'
alias nvrc='nv ~/.config/nvim/lua/{plugins/{core,python}.lua,config/{options,keymaps}.lua} +"Neotree show ~/.config/nvim"'
alias nvimrc=nvrc
alias listening='lsof -i -s TCP:Listen'
alias ports='sudo ss -tlnp | ( sed -u 1q ; sort -k 4)'

alias docker-prune='docker system prune -f --volumes'
alias docker-halt='docker container ls -a --format "{{.Names}}" | xargs -r docker container rm -f'
alias docker-scrub='docker-halt && docker-prune'
alias docker-purge='docker-halt && docker-prune -a'

alias loud='BASH_ENV=~/.bash_loud '
# alias verbose='BASH_ENV=~/.bash_verbose '

alias xclip='xclip -selection clipboard'

alias http='http --ignore-stdin'

alias ncdu='ncdu --exclude-caches --exclude=node_modules --exclude=cache --exclude=.cache --exclude=venv'

# become root, but with all my bells and whistles (not well tested)
alias super='sudo env HOME=$HOME /usr/local/bin/bash --login -i'

if [[ -f /usr/local/lib/antlr-4.9-complete.jar ]]; then
    alias grun='java -Xmx500M -cp "/usr/local/lib/antlr-4.9-complete.jar:$CLASSPATH" org.antlr.v4.gui.TestRig'
    alias antlr4='java -Xmx500M -cp "/usr/local/lib/antlr-4.9-complete.jar:$CLASSPATH" org.antlr.v4.Tool'
    # alias antlr4='java -Xmx500M -cp "/usr/local/lib/antlr-4.8-complete.jar:$CLASSPATH" org.antlr.v4.Tool'
    # alias antlr4='java -Xmx500M -cp "/usr/local/lib/antlr-4.7-complete.jar:$CLASSPATH" org.antlr.v4.Tool'
fi

alias help2man='help2man -N -L $LC_ALL'

# make aliases of the form ...=../..
# these are most useful with `shopt -s autocd`
pattern="..=.."
for _ in {1..20}; do
    pattern=".${pattern}/.."
    eval alias $pattern
done
unset pattern

# maxar specific

# this is a script now
# alias mxcurl='curl -s -H "Authorization: $(token)" -H "Accept: application/json, */*"'

alias eureka='eureka -s'
