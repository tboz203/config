# setup powerline
# shellcheck disable=2034

# If not running interactively or powerline already defined, do nothing
[[ $- != *i* ]] && return

# set powerline availability flag (for all programs)
if haveexe powerline && [[ ($TERM == *256color || $COLORTERM == truecolor) && $HAS_POWERLINE_FONTS ]]; then
    export HAS_POWERLINE=1
fi

# if this isn't working and you don't know why, make sure that
# `HAS_POWERLINE_FONTS` survives the ssh connection

if [[ -v HAS_POWERLINE && ! -v POWERLINE_ROOT ]]; then
    dirs=(
        "$HOME"/.local/lib/python*
        /usr/local/lib/python*
        /usr/lib/python*
    )
    for dir in "${dirs[@]}"; do
        candidate="$dir/site-packages/powerline"
        if [[ -d $dir && -d $candidate ]]; then
            export POWERLINE_ROOT="$candidate"
            break
        fi
    done
    if [[ ! -v POWERLINE_ROOT ]]; then
        unset HAS_POWERLINE
        echo >&2 "[!] Powerline root not found"
    fi
    unset dirs dir
fi

# we've exported what we can
[[ -v EXPORT_ONLY ]] && return

# start powerline
if [[ -v HAS_POWERLINE ]]; then
    # if `ss` is unavailable, or no matching powerline daemon socket exists
    if ! haveexe ss || [[ -z $(ss -Hax src @powerline-ipc-$UID) ]]; then
        # start powerline daemon
        powerline-daemon -q || true
    else
        _debug "skipping powerline-daemon start; appears online"
    fi

    # export POWERLINE_BASH_CONTINUATION=1
    # export POWERLINE_BASH_SELECT=1

    # gross hack to skip slow, redundant checks
    POWERLINE_COMMAND=powerline
    POWERLINE_CONFIG_COMMAND=true
    . "${POWERLINE_ROOT?}/bindings/bash/powerline.sh"
fi
