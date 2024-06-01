# ~/.bashrc
# vim: tw=119

declare -g _BASH_INIT_DEBUG
_BASH_INIT_DEBUG=1

[[ -v _BASH_INIT_DEBUG ]] && echo >&2 top of bash init

verbose()
{
    if [[ -v _BASH_INIT_DEBUG ]]; then
        echo >&2 "$@"
    fi
}

meerkat()
{
    [[ -v _BASH_INIT_DEBUG ]] || return
    : 'take a look around'
    declare -p SHELL BASH_VERSION BASH_SOURCE FUNCNAME
    pstree -Uas -H $$ $$
    [[ $- == *i* ]] && echo >&2 "# shell is interactive"
    shopt -q login_shell && echo >&2 "# shell is login"
}

# minimal path builder
pathmunge()
{
    [[ :$PATH: != *:$1:* && -d $1 ]] || PATH="$1:$PATH"
}

# check for an executable in the path
haveexe()
{
    type -P "$@" > /dev/null
}

# check for any callable
havecmd()
{
    type -t "$@" > /dev/null
}

bash_init()
{
    _BASH_INIT_STARTED=1

    pathmunge "$HOME/bin"
    pathmunge "$HOME/.bin"
    pathmunge "$HOME/.local/bin"

    export MAILTO=thomas.bozeman@cgifederal.com
    export LC_ALL=en_US.UTF-8
    export LANG=en_US.UTF-8
    export EDITOR=nvim
    export PAGER=less

    local item
    for item in ~/.bash_init.d/*; do
        if [[ $item =~ .*\.(sh|bash)$ ]]; then
            verbose "# sourcing init script $item"
            . "$item"
            havecmd _stop_debug_trace && _stop_debug_trace
        else
            echo >&2 "[!] will not source file: $item"
        fi
    done

    _BASH_INIT_DONE=1
}

meerkat

# don't run twice, and don't recurse
[[ -v _BASH_INIT_RUN ]] || bash_init

meerkat

# clear any debug trace before leaving
havecmd _stop_debug_trace && _stop_debug_trace

[[ -v _BASH_INIT_DEBUG ]] && echo >&2 bottom of bash init
