#!/usr/bin/env bash

for item in /usr/lib/jvm/*; do
    item=$(realpath -s "$item")
    printf '%s\n' "$item"
    while [[ -L $item ]]; do
        directory=$(dirname "$item")
        item=$(readlink "$item")
        if [[ $item != /* ]]; then
            item=$directory/$item
        fi
        item=$(realpath -s "$item")
        printf -- '-> %s\n' "$item"
    done
done

# for original in /usr/lib/jvm/*; do
#     original=$(realpath -s "$original")
#     # echo "original is $original"
#     item=$original
#     while [[ -L $item ]]; do
#         # echo "item is symlink: $item"
#         target=$(readlink "$item")
#         # echo "target is $target"
#         if [[ $target != /* ]]; then
#             target=$(dirname "$item")/$target
#             # echo "relative target; normalized to $target"
#         fi
#         target=$(realpath -s "$target")
#         # echo "canonicalized target to $target"
#         if [[ $item == "$original" ]]; then
#             echo "$item -> $target"
#         else
#             echo " ... $item -> $target"
#         fi
#         item=$target
#     done
# done
