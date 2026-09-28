#!/usr/bin/env bash

for item in *\ *; do
  clean=$(sed -r -e 's/[ ()]/%/g' -e 's/%%+/%/g' -e 's/(^|[._-])%|%($|[._-])/\1\2/g' -e 's/%/-/g' <<< "$item")
  mv "$item" "$clean"
done
