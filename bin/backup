#!/bin/bash
# 2013.02.08
# Tommy Bozeman

if [ -e "$1" ]; then
    item="$(echo "$1" | sed 's/\/$//' | sed -r 's/(.*\/)?\.?//')"
    if [ -d backups ]; then
        item=backups/$item
    fi
    new="$(date "+${item}-%Y.%m.%d-%H.%M.%S.7z")"
    7z a "$new" "$1"
    echo "[+] Name was \"$new\""
fi
