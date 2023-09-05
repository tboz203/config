#!/bin/bash
# color aliases
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias tree='tree -C --dirsfirst'
alias diff='diff --color=auto'

# some aliases based off ls
alias ls='ls --color=auto --ignore-backups --group-directories-first'
alias ll='ls -lhF'
alias la='ls -A'
alias lf='ll -S'
alias lv='ls --sort=v'
alias l='ls -CF'
alias lla='ll -A'
alias lt='ll --sort=t'

# these are most useful with `shopt -s autocd`
# alias ...='../..'
# alias ....='../../..'
# alias .....='../../../..'
# for i in $(seq 1 20); do
#     dotalias="..$( repeat . $i )"
#     dotdir="..$( repeat /.. $i )"
#     alias $dotalias=$dotdir
# done
# unset dotalias dotdir

_dots=..
_dirs=..
for x in $(seq 1 20); do
    _dots+=.
    _dirs+=/..
    alias $_dots=$_dirs
done
unset _dots _dirs

# some git commands
# start using the built-in git alias stuff!
# alias gits='git status'
# alias gitl='git log --graph --decorate --date-order --decorate-refs-exclude="*-staging-*" --oneline'
# alias gitlf='git log --graph --decorate --date-order --decorate-refs-exclude="*-staging-*" --format=bigline'
# alias gitla='gitl --all'
# alias gitlaf='gitlf --all'
# alias gitb='git branch -vva'
# alias gitr='git remote -vv'
# alias gitd='git diff'

# because i'm a moron sometimes
alias qgit='git'

# open each file in its own tab
# alias vim='vim -Xp'
alias vim='vim -p'
alias view='view -p'

# common misspellings
alias sl=ls
alias s=ls
alias fl=lf
alias f=lf
alias ivm=vim
alias vmi=vim
alias cdd=cd
alias dfn=dnf

# make du and df a bit more readable
alias df='df -h'
alias du='du -shc'

alias dfx='df -h -t xfs'

# make some basic commands default to verbose, interactive, and recursive (if
# not already)
alias mv='mv -vi'
alias cp='cp -vri'
alias rm='rm -vI --one-file-system'

# some aliases for date in a sortable format
alias day='date +%Y-%m-%d'
alias full='date "+%Y.%m.%d-%H.%M.%S"'

# set some default flags
alias tidy='tidy -f /dev/null -iqmw'
alias astyle='astyle -sajcn'
alias find='find 2>/dev/null'
alias nl='nl -ba'

# misc
alias rgrep='grep -r'
alias vimrc='vim ~/.vimrc'
alias gvimrc='gvim ~/.gvimrc'
alias aliases='vim ~/.bash_aliases'
alias bashrc='vim ~/.bashrc'
alias rmf='rm -rf'
alias ps='ps -H'
# alias listening='lsof -i -s TCP:Listen'
alias ports='sudo ss -tlnp | column -t'
alias docker-prune='docker system prune -f --volumes'
alias docker-halt='docker container ls -a --format "{{.Names}}" | xargs -r docker container rm -f'
alias docker-scrub='docker-halt && docker-prune'
alias docker-purge='docker-halt && docker-prune -a'
alias loud='BASH_ENV=~/.bash_loud'
alias xclip='xclip -selection clipboard'

alias svim='sudo vim "+set nu bg=dark ls=2 so=3" -p'

alias curl='curl -w "\n"'

alias http='http --ignore-stdin'

alias figlet='figlet -w $(tput cols)'

alias antlr4='java -Xmx500M -cp "/usr/local/lib/antlr-4.9-complete.jar:$CLASSPATH" org.antlr.v4.Tool'
# alias antlr4='java -Xmx500M -cp "/usr/local/lib/antlr-4.8-complete.jar:$CLASSPATH" org.antlr.v4.Tool'
# alias antlr4='java -Xmx500M -cp "/usr/local/lib/antlr-4.7-complete.jar:$CLASSPATH" org.antlr.v4.Tool'

# resolve symlinks
alias cd='cd -P'

# maxar specific

# this is a script now
# alias mxcurl='curl -s -H "Authorization: $(token)" -H "Accept: application/json, */*"'
# bootstrap depends on an old version of yq, so i've installed yq 4 as "yq-4"
alias yq='yq-4'

alias eureka='eureka -s'

# print out all variables, even if not exported
alias xenv='compgen -v | grep -v "^_" | sort | while read item; do declare -p $item ; done'
