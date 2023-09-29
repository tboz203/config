#!/bin/bash
# query CPR for LG01 contacts in the last 5 minutes

mxcurl $(eureka -e reg service://contact-plan-repository/*/reg/query) \
  -d "$(
    jq -c -n --arg start "$(date -Is --date=-5min | sed 's/+.*/Z/')"
    --arg stop "$(date -Is | sed 's/+.*/Z/')"
    '{"scid": "LG01", "startTime": $start, "stopTime": $stop}'
  )" | jq
