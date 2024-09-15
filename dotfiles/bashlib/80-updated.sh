# bashlib functions using modern features

((BASH_VERSINFO[0] >= 5)) || return 0

_fixargs() {
    local -a arguments
    while (($#)); do
        case $1 in
        --)
            # halt argument parsing; take all remaining args verbatim
            arguments+=("$@") && break
            ;;
        -*=*)
            # split --var=value pairs, preserving whitespace, and re-consider
            set -- "${1%%=*}" "${1#*=}" "${@:2}"
            ;;
        -[^-]?*)
            # split `-xyz` flags into `-x -y -z`, and re-consider
            local split=()
            for ((i = 1; i < ${#1}; i++)); do
                split+=("-${1:$i:1}")
            done
            set -- "${split[@]}" "${@:2}"
            ;;
        *)
            # others unmodified
            arguments+=("$1") && shift
            ;;
        esac
    done
    echo set -- "${arguments[@]@Q}"
}

showarray() {
    # pretty print array variables
    # usage: showarray ARRAYVAR...

    local -n arrayref
    for arrayref in "$@"; do
        local attrib
        if ! attrib=$(attributes "${!arrayref}"); then
            _warn "Could not determine attributes of ${!arrayref}"
            continue
        fi

        if [[ $attrib != *[aA]* ]]; then
            _err "Not an array: $arrayref"
            continue
        fi

        println "${!arrayref}=("
        local key
        for key in "${!arrayref[@]}"; do
            printf "  [%s]=%s\n" "$key" "${arrayref[$key]@Q}"
        done
        println ")"
    done
}
