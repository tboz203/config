# ~/.bashrc
# vim: tw=119

echo top of bashrc
pstree -a $PPID

[[ -v _BASHRC_RUN ]] && {
    echo already been here
    return
}
_BASHRC_RUN=1

for item in ~/.bashrc.d/*; do
    if [[ -f $item && -r $item && $item =~ .*\.(sh|bash)$ ]]; then
        echo sourcing item "$item"
        . "$item"
    else
        echo >&2 "[!] will not source file: $item"
    fi
done
unset item
