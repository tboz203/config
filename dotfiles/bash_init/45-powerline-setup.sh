# set up powerline
# shellcheck disable=2034

function find-powerline-root {
    if [[ -d ${POWERLINE_ROOT-} && $POWERLINE_ROOT == */powerline ]]; then
        _warn "POWERLINE_ROOT already set"
        return 0
    else
        unset POWERLINE_ROOT || true
    fi

    # local -a candidate_roots=(
    #     ~/.local/pipx/venvs/powerline-status
    #     ~/.local
    #     /usr/local
    #     /usr
    # )
    #
    # local python_root_glob="/lib/python[0-9].+([0-9])"
    #
    # local candidate_root python_root
    # for candidate_root in "${candidate_roots[@]}"; do
    #     for python_root in "$candidate_root"/lib/python3.+([0-9]); do
    #         powerline_candidate="$python_root/site-packages/powerline"
    #         if [[ -d $powerline_candidate ]]; then
    #             export POWERLINE_ROOT=$powerline_candidate
    #             return 0
    #         fi
    #     done
    # done

    local powerline_path
    powerline_path=$(type -P powerline | xargs realpath) || {
        _warn "Powerline executable not found"
        return 1
    }

    if [[ $powerline_path == */.pyenv/* ]] && type -P pyenv > /dev/null; then
        powerline_path=$(pyenv which powerline | xargs realpath) || {
            _warn "Pyenv Powerline installation appears broken"
            return 1
        }
    fi

    local first_match
    for first_match in "${powerline_path%/*/*}"/lib/python*/site-packages/powerline; do
        export POWERLINE_ROOT=$first_match
        return 0
    done

    # _warn "Powerline root not found"
    return 1
}

if [[ ! -d ${POWERLINE_ROOT-} ]]; then
    find-powerline-root
fi
