# setup powerline
# shellcheck disable=2034

[[ ${_SHELL_INTERACTIVE-} ]] || return 0
havebin powerline || return 0
[[ ($TERM == *256color || $COLORTERM == truecolor) && $HAS_POWERLINE_FONTS ]] || return 0

# if this isn't working and you don't know why, make sure that
# `HAS_POWERLINE_FONTS` survives the ssh connection

find_powerline_root()
{
    if [[ -d ${POWERLINE_ROOT-} && $POWERLINE_ROOT == */powerline ]]; then
        _warn "POWERLINE_ROOT already set"
        return 0
    fi

    local -a python_installations=(
        ~/.local/lib/python*
        /usr/local/lib/python*
        /usr/lib/python*
    )

    local dir
    for dir in "${python_installations[@]}"; do
        powerline_candidate="$dir/site-packages/powerline"
        if [[ -d $powerline_candidate ]]; then
            export POWERLINE_ROOT=$powerline_candidate
            return 0
        fi
    done

    _warn "Powerline root not found"
    return 1
}

if [[ ! ${POWERLINE_ROOT-} ]]; then
    find_powerline_root
fi

export HAS_POWERLINE=1

[[ ${_SHELL_INTERACTIVE-} ]] || return 0

if [[ ${HAS_POWERLINE-} ]]; then
    # if `ss` is unavailable, or no matching powerline daemon socket exists
    if ! havebin ss || [[ -z $(ss -Hax src @powerline-ipc-$UID) ]]; then
        # start powerline daemon
        powerline-daemon -q || true
    fi

    # export POWERLINE_BASH_CONTINUATION=1
    # export POWERLINE_BASH_SELECT=1

    # gross hack to skip slow, redundant checks
    POWERLINE_COMMAND=powerline
    POWERLINE_CONFIG_COMMAND=true
    . "${POWERLINE_ROOT?}/bindings/bash/powerline.sh"
fi
