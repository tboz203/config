# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc) for examples
# with (severe) modifications by tboz203
# vim: tw=119

: top of bashrc

# alias .=source
# source() {
#     shopt -oq verbose && echo sourcing "$@"
#     builtin source "$@"
#     shopt -oq verbose && echo leaving "$@"
# }

# functionless pathmunge ~/.local/bin to get powerline into PATH before attempting turbo mode
[[ :$PATH: == *:$HOME/.local/bin:* ]] || PATH=$HOME/.local/bin:$PATH

# ensure ssh, tmux, and powerline
[[ $- == *i* && -f ~/.turbo-mode.sh ]] && . ~/.turbo-mode.sh

export ANSIBLE_NOCOWS=1
export EDITOR=$HOME/.local/bin/vim
export PAGER=$HOME/.local/bin/less
export MAILTO=thomas.bozeman@cgifederal.com
export PYTHONSTARTUP=$HOME/.pythonrc.py
export REQUESTS_CA_BUNDLE=/etc/pki/ca-trust/extracted/openssl/ca-bundle.trust.crt
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export PIPENV_VENV_IN_PROJECT=1
export BOOST_ROOT=/home/tbozeman/.local/boost_1_82_0

# if we have our own installation of bash_completion, don't let
# /etc/profile.d/bash_completion.sh source the system installation
[[ -r $HOME/.local/share/bash-completion/bash_completion ]] && shopt -u progcomp

[[ -f /etc/bashrc ]] && . /etc/bashrc

[[ -f ~/.bash_functions ]] &&  . ~/.bash_functions

# counter-intuitively, later lines will be higher in the path
pathmungex PATH $HOME/workspace/maxar/do-dev

pathmungex PATH $HOME/.local/share/plantuml
pathmungex PATH $HOME/.local/share/jdt-language-server/bin
pathmungex PATH $HOME/.local/share/node/bin
pathmungex PATH $HOME/.local/share/flyway
pathmungex PATH $HOME/.local/share/pycharm/bin
pathmungex PATH $HOME/.local/share/Postman
pathmungex PATH $HOME/.local/share/idea/bin
pathmungex PATH $HOME/.local/share/groovy/bin
pathmungex PATH $HOME/.local/share/go/bin
pathmungex PATH $HOME/.local/bin

pathmungex PATH $HOME/go/bin
pathmungex PATH $HOME/.cargo/bin
pathmungex PATH $HOME/.poetry/bin
pathmungex PATH $HOME/.rbenv/bin
pathmungex PATH $HOME/.nodenv/bin
pathmungex PATH $HOME/.pyenv/bin
pathmungex PATH $HOME/.tfenv/bin
pathmungex PATH $HOME/.tgenv/bin
pathmungex PATH $HOME/.bin
pathmungex PATH $HOME/.maxar-bin

pathmungex --after PATH $HOME/.bootstrap/bin
pathmungex --after PATH $HOME/.bootstrap/java/default/bin
pathmungex --after PATH $HOME/.bootstrap/maven/default/bin
pathmungex --after PATH $HOME/.bootstrap/gradle/default/bin
pathmungex --after PATH $HOME/.bootstrap/miniconda/bin

pathmungex --after PATH /usr/pgsql-12/bin

export PERL_MB_OPT="--install_base /home/tbozeman/perl5";
export PERL_MM_OPT="INSTALL_BASE=/home/tbozeman/perl5";
pathmungex PATH /home/tbozeman/perl5/bin
pathmungex -e -a PERL_LOCAL_LIB_ROOT $HOME/perl5
pathmungex -e PERL5LIB $HOME/perl5/lib/perl5

pathmungex -e PYTHONPATH $HOME/.pymodules

# If not running interactively, don't do anything else
[[ $- == *i* ]] || return

# number one: complain
if [[ ${BASH_VERSINFO[0]} -lt 5 ]]; then
    echo >&2 "Hi! go update your bash please..."
fi

# if programmable completion wasn't activated by /etc/bashrc
# (or if we disabled it in ~/.config/bash_completion),
# re-enable it here
if ! shopt -q progcomp && [[ -r $HOME/.local/share/bash-completion/bash_completion ]] ; then
    shopt -s progcomp
    [[ ${BASH_VERSINFO[0]} -ge 5 ]] && shopt -s progcomp_alias
    . $HOME/.local/share/bash-completion/bash_completion
fi

[[ -f ~/.bash_aliases ]] && . ~/.bash_aliases

# don't save duplicate commands or commands starting with spaces in bash history
HISTCONTROL=ignoreboth
# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=
HISTFILESIZE=
HISTTIMEFORMAT="%h %d %H:%M:%S> "
HISTIGNORE="ls:la:lf:ll:l"

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# use a specific key for rsync over ssh
export RSYNC_RSH="ssh -i $HOME/.ssh/rsync_key"

# set autocd: if command is a directory, cd to it
shopt -s autocd
# set recursive globbing w/ "**"
shopt -s globstar

# dircolors
if ihave dircolors; then
    if [[ -r ~/.dircolors ]]; then
        eval "$(dircolors -b ~/.dircolors)"
    else
        eval "$(dircolors -b)"
    fi
fi

# attempt to set some options for LESS
# LESS="-SRFXJ"
export LESS="-SRFi"
# (less --mouse |& grep -q "no mouse option") || LESS+=" --mouse --wheel-lines=3"
(less --help |& grep -q "mouse") && LESS+=" --mouse --wheel-lines=3"

vimwhich () { vim $( /usr/bin/which $@ ); }
complete -c vimwhich

# these have been written to disk in order to reduce bash startup time. the
# bash completion ones are in ~/.local/share/bash-completion/completions and
# are lazily loaded at first use

# doihave thefuck && eval "$(thefuck --alias ugh)"
[[ -f ~/.ugh.sh ]] && . ~/.ugh.sh
# doihave poetry && eval "$(poetry completions bash)"
# doihave pipenv && eval "$(_PIPENV_COMPLETE=bash_source pipenv)"
# doihave kubectl && eval "$(kubectl completion bash)"
# doihave helm && eval "$(helm completion bash)"
# doihave oc && eval "$(oc completion bash)"
# doihave kind && eval "$(kind completion bash)"
# doihave yq && eval "$(yq shell-completion bash)"

export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"

if [[ -f /usr/local/lib/antlr-4.9-complete.jar ]]; then
    alias antlr4='java -Xmx500M -cp "/usr/local/lib/antlr-4.9-complete.jar:$CLASSPATH" org.antlr.v4.Tool'
    alias grun='java -Xmx500M -cp "/usr/local/lib/antlr-4.9-complete.jar:$CLASSPATH" org.antlr.v4.gui.TestRig'
fi

# [ -z $SSH_AUTH_SOCK ] && eval $(ssh-agent -s) >/dev/null 2>&1

export PYENV_ROOT=$HOME/.pyenv

export M2_HOME=/home/tbozeman/.bootstrap/maven/default
export JAVA_HOME=$HOME/.bootstrap/java/default

export SSL_CERT_FILE=/etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem

# When set to "1" suggest all commands, including plumbing commands
# which are hidden by default (e.g. "cat-file" on "git ca<TAB>").
export GIT_COMPLETION_SHOW_ALL_COMMANDS=1
# When set to "1" suggest all options, including options which are
# typically hidden (e.g. '--allow-empty' for 'git commit').
export GIT_COMPLETION_SHOW_ALL=1

export GIT_PS1_SHOWDIRTYSTATE=1
export GIT_PS1_SHOWSTASHSTATE=1
export GIT_PS1_SHOWUNTRACKEDFILES=1
export GIT_PS1_SHOWUPSTREAM=auto
# export GIT_PS1_COMPRESSSPARSESTATE=1
# export GIT_PS1_OMITSPARSESTATE=1
export GIT_PS1_SHOWCONFLICTSTATE=1
export GIT_PS1_DESCRIBE_STYLE=branch
export GIT_PS1_SHOWCOLORHINTS=1
export GIT_PS1_HIDE_IF_PWD_IGNORED=1

pathmungex -e PKG_CONFIG_PATH $HOME/local/lib/pkgconfig
pathmungex -e PKG_CONFIG_PATH $HOME/local/share/pkgconfig

# these have been written to disk in ~/.profile.d to reduce bash load time
# doihave pyenv && eval "$(pyenv init -)"
# doihave nodenv && eval "$(nodenv init -)"
# doihave rbenv && eval "$(rbenv init -)"

WB_TOOLS=$HOME/workspace/maxar/wb-team
# source $WB_TOOLS/source_all.sh
source $WB_TOOLS/bash_lib/aws_tools/awsCreds.sh
initaws() { awsCreds mcs-com us-east-1; }

for item in ~/.profile.d/*; do
    [[ -f $item && -r $item ]] && . $item
done
unset item

# -------- SNIP --------

# # >>> conda initialize >>>
# # !! Contents within this block are managed by 'conda init' !!
# __conda_setup=$($HOME/.bootstrap/miniconda/bin/conda shell.bash hook 2> /dev/null)
# if [ $? -eq 0 ]; then
#     eval "$__conda_setup"
# else
#     if [ -f "$HOME/.bootstrap/miniconda/etc/profile.d/conda.sh" ]; then
#         . "$HOME/.bootstrap/miniconda/etc/profile.d/conda.sh"
#     else
#         export PATH="$HOME/.bootstrap/miniconda/bin:$PATH"
#     fi
# fi
# unset __conda_setup
# # <<< conda initialize <<<

: end of bashrc
