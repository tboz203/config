#!/usr/bin/env bash

if (($# == 0)); then
    echo >&2 "[X] $0: add certificate authorities to Chrome's trust store."
    echo >&2 "[X] Usage: $0 CERT [CERT...]"
    exit 1
fi

for arg in "$@"; do
    if [[ $arg == -* ]]; then
        echo >&2 "[X] $0: add certificate authorities to Chrome's trust store."
        echo >&2 "[X] Usage: $0 CERT [CERT...]"
        exit 1
    fi
done

if ! type -P certutil > /dev/null; then
    echo >&2 '[X] certutil not found; do you have `libnss3-tools`?'
    exit 1
fi

CERT_DIR=$HOME/.pki/nssdb
mkdir -p "$CERT_DIR"

for arg in "$@"; do
    certutil -A -d "sql:$CERT_DIR" -n "$arg" -i "$arg" -t CT,c,c
done
