#!/usr/bin/env bash
# make a pretty PS1
# shellcheck disable=2016,2034

[[ ${_SHELL_INTERACTIVE-} ]] || return 0

function simple-prompt {
    unset PROMPT_COMMAND
    PS1='\[\e[1;33m\]\u \w \$ \[\e[0m\]'
}

function build-color {
    # build an (escaped) ANSI escape code color sequence

    local -a parts
    local slot=30
    while (($# > 0)); do
        local arg=$1 && shift
        case $arg in
            reset) parts+=(0) ;;
            bold) parts+=(1) ;;
            dim) parts+=(2) ;;
            italic) parts+=(3) ;;
            underline) parts+=(4) ;;
            blink) parts+=(5) ;;
            reverse) parts+=(7) ;;
            hidden) parts+=(8) ;;
            strike) parts+=(9) ;;
            black) parts+=($((slot + 0))) ;;
            red) parts+=($((slot + 1))) ;;
            green) parts+=($((slot + 2))) ;;
            yellow) parts+=($((slot + 3))) ;;
            blue) parts+=($((slot + 4))) ;;
            magenta) parts+=($((slot + 5))) ;;
            cyan) parts+=($((slot + 6))) ;;
            white) parts+=($((slot + 7))) ;;

            fg) slot=30 ;;
            bg) slot=40 ;;

            *)
                _warn "Unknown option: \"$arg\""
                return 2
                ;;
        esac
    done

    ((${#parts[@]} > 0)) || throw "Nothing specified"

    print "\001\e[${parts[0]}"
    printeach ";%s" "${parts[@]:1}"
    print "m\002"
}

function __last_status_ps1 {
    # print the return status of the last command in color
    local last_status=$?

    if [[ ${1-} == +([0-9]) ]]; then
        last_status=$1
    fi

    local display=$last_status
    if ((last_status & 128)); then
        # try to interpret signal status codes
        display=$(builtin kill -l $((last_status & 127)) 2> /dev/null) || display=$last_status
    fi

    local statuscolor
    if ((last_status > 0)); then
        statuscolor=$(build-color reset bold white bg red)
    else
        statuscolor=$(build-color reset dim)
    fi

    # adding newline so that this still looks okay when used by itself;
    # the `$(...)` wrapping the function in PS1 will strip it back out
    printf "%b(%s)%b\n" "$statuscolor" "$display" "$(build-color reset)"
    return "$last_status"
}

function __prompt_ll_on_cd {
    # list files on directory change
    local last_retval=$?
    [[ -z ${__last_cwd-} || $__last_cwd == "$PWD" ]] || ls -lhF
    declare -g __last_cwd=$PWD
    return $last_retval
}

function pretty-prompt {
    # build & set a nice bash prompt

    # first, politely disable powerline prompt
    function _powerline_status_wrapper {
        true
    }

    local usercolor
    if ((EUID == 0)); then
        # for root
        usercolor=red
    elif ((EUID < 1000)); then
        # for services
        usercolor=magenta
    else
        # for users
        usercolor=green
    fi

    local -a parts
    parts=("$(build-color reset bold "$usercolor")" '\u')

    if [[ -v SSH_CONNECTION ]]; then
        # bold white `@` and red hostname
        parts+=("$(build-color reset bold white)" '@' "$(build-color red)" '\h')
    fi

    # working directory (shortened in home directory) in blue
    parts+=(" $(build-color reset bold blue)" '\w')

    # add git prompt, if available
    if (declare -F __git_ps1 && type -P git) > /dev/null; then
        parts+=("$(build-color reset)" '$(__git_ps1 ":(%s)")')
    fi

    # include the result of the last command, in color
    parts+=(' $(__last_status_ps1)')

    # pound sign if superuser, otherwise dollar sign
    parts+=(" $(build-color bold white)" '\$ ' "$(build-color reset)")

    # combine & assign to prompt
    printf -v PS1 "%s" "${parts[@]}"
}

# [[ $PROMPT_COMMAND == *__prompt_ll_on_cd* ]] || PROMPT_COMMAND+=$'\n__prompt_ll_on_cd'
[[ $PROMPT_COMMAND == *powerline* ]] || pretty-prompt
