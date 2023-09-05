#!/usr/bin/bash -e
# vim: tw=0

ANYTHING=

envs=(
    devint-us-east-1
    reg-us-east-1
    dev-us-east-1
)

for env in "${envs[@]}"; do
    url=$(eureka -e $env event-service-consumer-proxy)

    links=( $(mxcurl $url/subscriptions | jq -r --arg HOST "$HOSTNAME" '._embedded.subscriptions[] | select(.deliveryMethod.endpoint // "" | contains($HOST)).id.href') )
    : "${links[@]}"
    for link in "${links[@]}"; do
        ANYTHING=1
        echo "[.] Deleting $link"
        mxcurl -X DELETE $link
    done
done

if [[ ! $ANYTHING ]]; then
    echo "[.] Nothing to delete"
fi
