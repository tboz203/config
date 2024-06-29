# setup powerline
# shellcheck disable=2034

# [[
#     ${_SHELL_INTERACTIVE-} &&
#     ${HAVE_POWERLINE_FONTS-} &&
#     ($TERM == *256color || $COLORTERM == truecolor) ]] &&
#     havebin powerline || return 0

# if this isn't working and you don't know why, make sure that
# `HAVE_POWERLINE_FONTS` survives the ssh connection

find_powerline_root() {
    if [[ -d ${POWERLINE_ROOT-} && $POWERLINE_ROOT == */powerline ]]; then
        _warn "POWERLINE_ROOT already set"
        return 0
    fi

    local -a candidate_roots=(
        ~/.local/pipx/venvs/powerline-status
        ~/.local
        /usr/local
        /usr
    )

    local python_root_glob="/lib/python[0-9].+([0-9])"

    local candidate_root python_root
    for candidate_root in "${candidate_roots[@]}"; do
        for python_root in "$candidate_root"/lib/python3.+([0-9]); do
            powerline_candidate="$python_root/site-packages/powerline"
            if [[ -d $powerline_candidate ]]; then
                export POWERLINE_ROOT=$powerline_candidate
                return 0
            fi
        done
    done

    _warn "Powerline root not found"
    return 1
}

if [[ ! ${POWERLINE_ROOT-} ]]; then
    find_powerline_root
fi

[[ ${_SHELL_INTERACTIVE-} ]] || return 0

if [[ -d ${POWERLINE_ROOT-} ]]; then
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
