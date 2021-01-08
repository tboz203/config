#!/usr/bin/bash


# want to only print output if the command fails;
# would also like to print it all at once instead of as the command executes

update() {
    local repo=$1
    pushd $repo &> /dev/null

    # this function should ignore subprojects
    [[ $( git rev-parse --show-superproject-working-tree ) ]] && return 0

    errors=()

    capture="$( git fetch --all --prune 2>&1 )" || errors+=( "$capture" )

    refs="$( git for-each-ref refs/heads --format="%(refname:short)" )"

    for item in $refs; do
        remote="$( git config --get branch.$item.remote )"
        upstream="$( git config --get branch.$item.merge )"
        if [[ $remote && $upstream ]]; then
            upstream="$( git rev-parse --abbrev-ref "$upstream" )"
            capture="$( git fetch -u $remote $upstream:$item 2>&1 )" || errors+=( "$capture" )
        fi
    done

    # capture="$( git fetch --all --prune 2>&1 )" || errors+=( "$capture" )
    # capture="$( git pull --ff-only 2>&1 )" || errors+=( "$capture" )

    popd &> /dev/null

    if [[ ${#errors[@]} -gt 0 ]]; then
        echo "[X] $repo"
        if [[ $VERBOSE ]]; then 
            for error in "${errors[@]}"; do
                echo "$error" | sed "s/^/    /"
            done
            echo
        fi
    fi

    return ${#errors[@]}
}

while [[ $# -gt 0 ]]; do

    arg="$1" ; shift
    case $arg in
        -h|--help)
            HELP=1 ;;
        -d|--depth)
            DEPTH="-maxdepth $1" ; shift ;;
        -v|--verbose)
            VERBOSE=1 ;;
        -*)
            echo "[X] I don't understand this argument: ($arg)"
            HELP=1
            ;;
        *)
            if [[ -z $ROOT ]]; then
                ROOT="$arg"
            else
                echo "[X] I don't understand this argument: ($arg)"
                HELP=1
            fi
            ;;
    esac
done

if [[ $HELP ]]; then
    cat <<EOF
Usage: $0 [-h|--help] [-d|--depth DEPTH] [ROOT]

Search for git repositories & update them.

Arguments:
ROOT:               (optional) The root under which to search for git repositories.

Options:
-h|-help            Print out this message.
-d|--depth DEPTH    Maximum depth at which to look for git repositories.
-v|--verbose        print out error messages
EOF

    exit 1
fi

# we should probably set some qualifiers on this `find` call...
for repo in $(find $ROOT $DEPTH -type d -name .git); do
    # update each repo (mostly) silently in the background
    update "$(dirname $repo)" &
done

wait

