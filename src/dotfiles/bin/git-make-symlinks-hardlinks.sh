#!/usr/bin/env bash

set -eu

# move to the root of the repository (or exit when not in a repository)
cd "$(git rev-parse --show-toplevel)"

function harden_link {
    # make git's broken symbolic links into hard links

    link=$1

    if [[ ! -e $link ]]; then
        echo >&2 "[!] link $link does not exist"
        return 1
    fi

    # try to dereference the link:
    readarray target < "$link"

    if [[ ${#target[@]} -ne 1 || ${target[0]} =~ $'\n' ]]; then
        echo "[!] link $link does not look like a link"
        return 1
    fi

    if [[ $target != /* ]]; then
        # looks like a relative link; try to build the correct path
        target=$(dirname "$link")/$target
    fi

    if [[ ! -e $target ]]; then
        echo >&2 "[!] target $target does not exist"
        return 1
    fi

    # remove the tracked (currently broken) link
    rm "$link"
    # create hard link `link` pointed at `target`
    ln "$target" "$link"
    # ignore the change in the index
    git update-index --assume-unchanged "$link"
}


# list file modes and paths known to git
git ls-files --format="%(objectmode):%(path)" |
    # pick out symbolic links
    grep '^120000' |
    # strip mode information
    cut -d: -f2- |
    # and try to make each one into a hard link
    while read -r link; do
        harden_link "$link" || continue
    done
