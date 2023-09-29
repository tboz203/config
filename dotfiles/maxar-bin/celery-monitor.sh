#!/bin/bash
# dumb script to monitor scheduled / active / reserved tasks

watch -n 5 "
  echo scheduled ;
  dodev run-command celery inspect scheduled --json 2>/dev/null |
    tail -n 1 |
    jq -c 'to_entries[] | .value[] | .request | {id, name}' ;
  echo active ;
  dodev run-command celery inspect active --json 2>/dev/null |
    tail -n 1 |
    jq -c 'to_entries[] | .value[] | {id, name}' ;
  echo reserved ;
  dodev run-command celery inspect reserved --json 2>/dev/null |
    tail -n 1 |
    jq -c 'to_entries[] | .value[] | {id, name}'"
