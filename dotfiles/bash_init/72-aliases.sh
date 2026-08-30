# bash aliases
# ------------

function binalias {
    havebin "$1" && eval "alias \"$1\"='$2'"
}

if havebin tree; then
    BASH_ALIASES['tree']='tree -C --dirsfirst --noreport --filelimit=50'
    if [[ $(\tree --version) > "tree v2.0.0" ]]; then
        BASH_ALIASES['tree']+=' --metafirst --sort=version'
    fi
    alias lt='tree -pugDF --si --du --gitignore'
    alias lta='tree -pugDF --si --du -a'
    alias ltc='tree --filelimit=1000 | column'
fi

alias _ls='\ls --color=auto --group-directories-first --sort=version'
alias ls='_ls --ignore-backups --ignore="ntuser.dat*" --ignore="NTUSER.DAT*"'
alias la='_ls -A'
alias ll='ls -lhF'
alias lla='la -lhF'
alias lll='ll -L'
# alias lt='ls --sort=time'
# alias llt='ll --sort=time'
alias l.='la -I "[^.]*"'
alias ll.='lla -I "[^.]*"'
alias l='ls -CF'
alias lf='ll -S'

if havebin vim; then
    alias vim='vim -p'
    # alias vim='nvim'
    alias view='view -p'
    # alias view='nvim -R'
fi

if havebin nvim; then
    alias nv=nvim
    alias nvdiff='nv -d'
    alias nvimdiff=nvdiff
fi

alias mv='mv -vi'
alias cp='cp -vri'
alias rm='rm -vI --one-file-system'

alias grep='grep --color=auto'
alias fgrep='grep -F'
alias egrep='grep -E'
alias rgrep='grep -r'
alias c='clear'
alias clear='clear -x'

if [[ $(diff --help 2>&1) == *'--color'* ]]; then
    alias diff='diff --color=auto'
fi

binalias watch 'watch '
binalias sudo 'sudo '

binalias tidy 'tidy -f /dev/null -iqmw'
binalias astyle 'astyle -sajcn'
binalias nl 'nl -ba'
binalias figlet 'figlet -t'
binalias ps 'ps -H'
binalias df 'df -hT -x tmpfs'
binalias xclip 'xclip -selection clipboard'
binalias http 'http --ignore-stdin'
binalias ncdu 'ncdu --exclude-caches --exclude=node_modules --exclude=cache --exclude=.cache --exclude=venv --exclude=tmp'
binalias help2man 'help2man -N -L $LC_ALL'
# alias info='info --vi-keys'

# editing rc files
# ----------------

alias vimrc='vim --cmd "cd ~/config/dotfiles" ~/config/dotfiles/vimrc'
alias bashrc='nv --cmd "cd ~/config/dotfiles" ~/config/dotfiles/{bashrc,bash_init/3?-*.sh}'
alias aliases='nv --cmd "cd ~/config/dotfiles" ~/config/dotfiles/bash_init/??-aliases.sh'
alias nvbashlib='nv --cmd "cd ~/config/dotfiles/bashlib" ~/config/dotfiles/bashlib{,/??-*}.sh'
alias nvbash_init='nv --cmd "cd ~/config/dotfiles/bash_init" ~/config/dotfiles/{bashrc,bash_init/??-*.sh}'
alias nvrc='nv --cmd "cd ~/config/configfiles/nvim" ~/config/configfiles/nvim/lua/plugins/{editor,language}.lua'

# misspellings
# ------------

alias sl=ls
alias s=ls
alias fl=lf
alias ivm=vim
alias vmi=vim
alias dc=cd
alias cdd=cd
alias dfn=dnf
alias qgit=git
alias vn=nv

# abbreviations & remappings
# --------------------------

# alias cat=bat

alias py='python'
alias ipy='ipython'
alias hd='hexdump -C'
# more complicated git aliases live in gitconfig
alias gits='git s'
alias upr='update-repos -tvl'

# "reverse" binaliases
havebin tokei && alias cloc=tokei
havebin mvnd && alias mvn='mvnd '
havebin wslview && alias open='wslview'

# new creations
# -------------

# not havebin-guarding these b/c docker desktop will often add docker to the
# path after login
alias docker-prune='docker container prune -f && docker volume prune -f && docker image prune -f && docker network prune -f'
alias docker-halt='docker container ls -a --format "{{.Names}}" | xargs -r docker container rm -f'
alias docker-scrub='docker system prune -f --all --volumes'
alias docker-purge='docker-halt && docker-scrub'

alias dfx='df -h -t xfs'
alias files='fd -t f'
# alias open='gio open'
# alias listening='lsof -i -s TCP:Listen'
# attempting to sort by listening address; not 100% effective
# alias ports='sudo ss -tlnp | ( sed -u 1q ; sort -k 4)'

havebin sudo && alias super='sudo HOME=$HOME $BASH --login -i'

# make aliases of the form `...=../..`, `....=../../..`, etc
# these are most useful with `shopt -s autocd`
pattern="..=.."
for _ in {1..20}; do
    pattern=".${pattern}/.."
    eval alias $pattern
done
unset pattern
