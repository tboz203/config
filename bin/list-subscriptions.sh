#!/usr/bin/env bash
# vim: tw=0

trap 'echo "got ($?) on line ($LINENO): $BASH_COMMAND"' ERR

set -eEuo pipefail

while [[ $# -gt 0 ]]; do
    arg="$1"; shift
    case $arg in
        (-d|--dump)
            DUMP=1
            ;;
        (-v|--verbose)
            VERBOSE=1
            unset DUMP NAMES LINKS
            ;;
        (-q|--quiet)
            QUIET=1 ;;
        (-n|--names)
            NAMES=1
            unset DUMP VERBOSE LINKS
            ;;
        (-l|--links)
            LINKS=1
            unset DUMP VERBOSE NAMES
            ;;
        (-m|--match-name)
            PATTERN="$1"; shift
            unset DUMP IDENTITY
            ;;
        (-i|--identity)
            IDENTITY="$1"; shift
            unset DUMP PATTERN
            ;;
        (--delete)
            # intentionally not unsetting `DUMP` here
            DELETE=1 ;;
        (-h|--help)
            HELP=1 ;;
        (*)
            echo "I don't understand '$arg'"
            USAGE=1 ;;
    esac
done

if [[ -v USAGE || -v HELP ]]; then
    cat <<EOF
List event serivice subscriptions. By default, find subscriptions matching our
client ID (per ~/.ssh/P2020), and output subscription urls.
Usage: $(basename $0) [-h|--help] [OPTIONS]
EOF
fi

if [[ -v HELP ]]; then
    cat <<EOF

Options:

-h|--help           Print this text and exit.
-q|--quiet          Suppress the informational output displayed when no services are matched
-d|--dump           Don't attempt to match against anything; dump all subscription json
-v|--verbose        Dump the full subscription json
-n|--names          Output names instead of links
-m|--match-name     Match the subscription name against this (jq) regex
-i|--identity       match based on this P2020 client identity

--delete            after printing, delete matched subscriptions (be careful!)

In the case of conflicting options, the last option specified on the command
line takes precedence.

--dump conflicts with everything else
--names and --verbose conflict with each other
--match-name and --identity conflict with each other
EOF
fi

if [[ -v USAGE || -v HELP ]]; then
    exit 0
fi

envs=(
    reg-us-east-1
    dev-us-east-1
)

for env in "${envs[@]}"; do
    url=$(eureka -e $env event-service-consumer-proxy | sed 's:/$::')

    if [[ -v DUMP ]]; then
        mxcurl $url/subscriptions | jq .
        ANYTHING=1
    else

        if [[ -v PATTERN ]]; then
            query="._embedded.subscriptions[]? | select(.name | test(\"$PATTERN\"))"
        else
            if [[ ! -v IDENTITY ]]; then
                IDENTITY="$( . ~/.ssh/P2020 ; echo "$P2020_IDENTITY_CLIENT_ID" )"
            fi
            query="._embedded.subscriptions[]? | select(.clientID == \"$IDENTITY\")"
        fi

        payloads=( "$(mxcurl $url/subscriptions | jq -r --arg HOST "$HOSTNAME" "$query" )" )

        for body in "${payloads[@]}"; do
            [[ "$body" ]] || continue
            ANYTHING=1
            if [[ -v VERBOSE ]]; then
                jq . <<< "$body"
            elif [[ -v NAMES ]]; then
                jq -r '.name' <<< "$body"
            elif [[ -v LINKS ]]; then
                jq -r '.deliveryMethod.endpoint' <<< "$body"
            else
                jq -r '.id.href' <<< "$body"
            fi
            if [[ -v DELETE ]]; then
                mxcurl -X DELETE $( jq -r '.id.href' <<< "$body" )
            fi
        done
    fi
done

if [[ ! -v ANYTHING && ! -v QUIET ]]; then
    echo "[.] Nothing matched"
fi

