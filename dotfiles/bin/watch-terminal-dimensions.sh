#!/usr/bin/env bash

redisplay() {
  clear
  figlet "$LINES x $COLUMNS"
}

trap 'redisplay' SIGWINCH

redisplay

while true; do
  sleep 0.1
done
