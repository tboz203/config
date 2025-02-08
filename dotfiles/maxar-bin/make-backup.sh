#!/bin/bash
# create a backup of important directories

set -euo pipefail
trap 'echo "err ($?) on line ($LINENO): $BASH_COMMAND"' ERR

RECIPIENT=thomas.bozeman@maxar.com
USER=th026106
INPUTS=("/home/" /usr/local /etc)
TITLE="backup-$(date +%Y-%m-%d)"
TARBALL="$PWD/${TITLE}.tar.zst.gpg"

if [[ $# -gt 0 ]]; then
    echo >&2 "$0: create local backups; takes no arguments"
    echo >&2 "the input directories are: ${INPUTS[*]}"
    echo >&2 "the output archive would be: $TARBALL"
    echo >&2 "Note: must be run as root"
    exit 1
fi

if [[ $UID -ne 0 ]]; then
    echo >&2 "[X] run this script as root"
    exit 1
fi

echo >&2 "[.] Creating backup for $USER: $TARBALL"
echo >&2 "[.] Starting: $(date)"

WORKSPACE="/home/$USER/$TITLE"
# NOTE: workspace will remain on ERR
trap 'rm -rf $WORKSPACE' EXIT
mkdir -p "$WORKSPACE" && cd "$WORKSPACE"

# make a local copy of all yum installs
(yumdb search command_line '*' || echo "[X] could not list installs") &> installs.txt
(yum history info '*' || echo "[X] could not read history") &> yum-history.txt

# and of brew installs
# which brew &> /dev/null && brew list --installed-on-request > brew-installs.txt
(sudo -u "$USER" -i brew list --installed-on-request || echo "[X] could not list installs") &> brew-installs.txt

# grab crontabs
crontab -u "$USER" -l > "$USER.crontab" || true
crontab -l > "root.crontab" || true

# do the thing
tar -c \
    --ignore-failed-read --absolute-names \
    --exclude-caches --exclude-backups --exclude=.cache --exclude=cache --exclude=tmp \
    -- . "${INPUTS[@]}" |
    zstd --long -7 |
    gpg --batch --encrypt --output "$TARBALL" --recipient "$RECIPIENT" \
        --trust-model always --compress-algo none

chown "$USER" "$TARBALL"
chmod 640 "$TARBALL"
ls -lhF "$TARBALL"
echo "[.] complete: $(date)"
