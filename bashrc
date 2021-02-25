# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc) for examples
# with modifications by tboz203
# vim: tw=119

export ANSIBLE_NOCOWS=1

# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

# If not running interactively, don't do anything
case $- in
    *i*) ;;
    *) return ;;
esac

pathmunge () {
    case ":${PATH}:" in
        *:"$1":*)
            ;;
        *)
            if [ -d "$1" ] ; then
                if [ "$2" = "after" ] ; then
                    PATH=$PATH:$1
                else
                    PATH=$1:$PATH
                fi
            fi
    esac
}


# fix TERM for tmux (otherwise powerline doesn't work well)
if [[ $TERM != *256color && $COLORTERM == gnome-terminal || $COLORTERM == xfce4-terminal ]]; then
    export TERM=xterm-256color
elif [[ $COLORTERM == rxvt-xpm ]]; then
    export TERM=rxvt-256color
fi

# set powerline availability flag (for all programs)
if [[ $(which powerline 2>/dev/null) && $TERM == *256color && $HAS_POWERLINE_FONTS ]]; then
    export HAS_POWERLINE=1
fi

if [[ $HAS_POWERLINE ]]; then
    for _location in {/usr,/usr/local,$HOME/.local}/lib/python*/site-packages/powerline; do
        if [[ -d $_location ]]; then
            _root=$_location
        fi
    done
    if [[ $_root ]]; then
        export POWERLINE_ROOT=$_root
    else
        echo >&2 "[-] Powerline root not found"
        read -p "press enter to continue: "
        unset HAS_POWERLINE
    fi
    unset _location _root
fi

# if has tmux and not nested, change process to new session
if [[ -x $( which tmux 2> /dev/null ) ]] && [[ -z "$TMUX" ]] && [[ -z $NO_TMUX ]]; then
    exec tmux new-session -A -s main
fi

# ignore something-or-other (i think it's `ls` and `cd`?)
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

# make less more friendly for non-text input files, see lesspipe(1)
[[ -x /usr/bin/lesspipe ]] && eval "$(SHELL=/bin/sh lesspipe)"

# set our prompt, depending on powerline availability
if [[ $HAS_POWERLINE ]]; then
    powerline-daemon -q
    # export POWERLINE_BASH_CONTINUATION=1
    # export POWERLINE_BASH_SELECT=1
    .  $POWERLINE_ROOT/bindings/bash/powerline.sh
else

    case "$TERM" in
        *color*) color_prompt=yes;;
    esac

    if [ "$color_prompt" = yes ]; then
        black="\[\e[0;30m\]"
        BLACK="\[\e[1;30m\]"
        red="\[\e[0;31m\]"
        RED="\[\e[1;31m\]"
        green="\[\e[0;32m\]"
        GREEN="\[\e[1;32m\]"
        yellow="\[\e[0;33m\]"
        YELLOW="\[\e[1;33m\]"
        blue="\[\e[0;34m\]"
        BLUE="\[\e[1;34m\]"
        magenta="\[\e[0;35m\]"
        MAGENTA="\[\e[1;35m\]"
        cyan="\[\e[0;36m\]"
        CYAN="\[\e[1;36m\]"
        white="\[\e[0;37m\]"
        WHITE="\[\e[1;37m\]"
        reset="\[\e[0m\]"
    fi

    u_color="$([[ "$EUID" -eq 0 ]] && echo "$RED" || echo "$GREEN")"
    PS1="${u_color}\u${WHITE}@${GREEN}\h${WHITE} ${BLUE}\w ${reset}"
    unset red RED green GREEN yellow YELLOW blue BLUE magenta MAGENTA cyan CYAN
    unset white WHITE reset color_prompt force_color_prompt

    # list files on directory change
    PROMPT_COMMAND='[[ ${__new_wd:=$PWD} != $PWD ]] && ll; __new_wd=$PWD'

    if [[ -f ~/.git-prompt ]]; then
        . ~/.git-prompt
        GIT_PS1_SHOWDIRTYSTATE=1
        GIT_PS1_SHOWSTASHSTATE=1
        GIT_PS1_SHOWUNTRACKEDFILE=1
        GIT_PS1_SHOWCOLORHINTS=1
        PS1+='$(__git_ps1 ":(%s)")'
    fi

    PS1+="${WHITE}$ ${reset}"
fi

# use a specific key for rsync over ssh
export RSYNC_RSH="ssh -i $HOME/.ssh/rsync_key"

# set autocd: if command is a directory, cd to it
shopt -s autocd
# set recursive globbing w/ "**"
shopt -s globstar

# Alias definitions.
if [[ -f ~/.bash_aliases ]]; then
    . ~/.bash_aliases
fi

# Function definitions.
if [[ -f ~/.bash_functions ]]; then
    . ~/.bash_functions
fi

# Enable programmable completion features.
if [[ -f /etc/bash_completion ]] && ! shopt -oq posix; then
    . /etc/bash_completion
    # complete -c export
fi

# dircolors
if [[ -x /usr/bin/dircolors ]]; then
    if [[ -r ~/.dircolors ]]; then
        eval "$(dircolors -b ~/.dircolors)"
    else
        eval "$(dircolors -b)"
    fi
fi

if [[ -x $(which thefuck 2>/dev/null) ]]; then
    eval "$(thefuck --alias ugh)"
fi

if [[ -x $(which pipenv 2>/dev/null) ]]; then
    eval "$(pipenv --completion)"
fi

# if [[ -x $(which kubectl 2>/dev/null) ]]; then
#     source <(kubectl completion bash)
# fi

# if [[ -x $(which oc 2>/dev/null) ]]; then
#     eval "$(oc completion bash)"
# fi

pathmunge $HOME/go/bin after

showmounts() {
    # list mounts in a table, and cut off the options
    mount -l "$@" | cut -d "(" -f 1 | sed -r "s/\<(on|type)\>/% \0/g" | column -t -s %
}

vimwhich () { vim $( which $@ ); }
complete -c vimwhich

# script to allow easily setting KUBECONFIG
[[ -f ~/.setkubeconfig.sh ]] && . ~/.setkubeconfig.sh

pathmunge /home/tbozeman@cgifederal.com/perl5/bin after
export PERL5LIB="/home/tbozeman@cgifederal.com/perl5/lib/perl5${PERL5LIB:+:${PERL5LIB}}"
export PERL_LOCAL_LIB_ROOT="/home/tbozeman@cgifederal.com/perl5${PERL_LOCAL_LIB_ROOT:+:${PERL_LOCAL_LIB_ROOT}}"
export PERL_MB_OPT="--install_base \"/home/tbozeman@cgifederal.com/perl5\""
export PERL_MM_OPT="INSTALL_BASE=/home/tbozeman@cgifederal.com/perl5"

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

if [[ -f /usr/local/lib/antlr-4.9-complete.jar ]]; then
    alias antlr4='java -Xmx500M -cp "/usr/local/lib/antlr-4.9-complete.jar:$CLASSPATH" org.antlr.v4.Tool'
    alias grun='java -Xmx500M -cp "/usr/local/lib/antlr-4.9-complete.jar:$CLASSPATH" org.antlr.v4.gui.TestRig'
fi

pathmunge /opt/apps/oracle/oracle12.1.0.2/product/12.1.0.2/client_1/bin after
[ -z $SSH_AUTH_SOCK ] && eval $(ssh-agent -s) >/dev/null 2>&1
export JAVA_HOME=/dg/local/cots/java/default
[[ ":${PATH}:" != *":/dg/local/cots/java/default/bin:"* ]] && PATH="/dg/local/cots/java/default/bin:${PATH}"
export M2_HOME=/dg/local/cots/maven/default
[[ ":${PATH}:" != *":/dg/local/cots/maven/default/bin:"* ]] && PATH="/dg/local/cots/maven/default/bin:${PATH}"
[[ ":${PATH}:" != *":/dg/local/cots/gradle/default/bin:"* ]] && PATH="/dg/local/cots/gradle/default/bin:${PATH}"
[[ ":${PATH}:" != *":/home/tbozeman/.tfenv/bin:"* ]] && PATH="/home/tbozeman/.tfenv/bin:${PATH}"
[[ ":${PATH}:" != *":/home/tbozeman/.tgenv/bin:"* ]] && PATH="/home/tbozeman/.tgenv/bin:${PATH}"
export PYENV_ROOT=$HOME/.pyenv
[[ ":${PATH}:" != *":$HOME/.pyenv/bin:"* ]] && PATH="$HOME/.pyenv/bin:${PATH}"
[[ ":${PATH}:" != *":$HOME/.pyenv/shims:"* ]] && PATH="$HOME/.pyenv/shims:${PATH}"
if ! hash pyenv; then eval $(pyenv init -); fi
