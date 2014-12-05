#!/bin/bash

if [ $UID -ne 0 ]; then
    echo "[-] Run this command as root!"
    exit 1
fi

apt-get update && apt-get upgrade
