#!/usr/bin/env bash
{
    echo -e "\npackage | version | description\n"
    aptitude search '~i !~M ~poptional !?reverse-depends(~i)' -F '%p | %v | %d'
} | sed -r 's/^/# /g' | column -t -s '|' -L
