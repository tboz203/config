# Wideband Team Tools

alias eureka='eureka -s '
alias rake='bundle exec rake '

if setpath -er WB_TOOLS ~/workspace/maxar/wb-team; then
    # source $WB_TOOLS/source_all.sh
    source "$WB_TOOLS/bash_lib/aws_tools/awsCreds.sh"
    alias initaws='awsCreds2 mcs-gov us-gov-west-1'
else
    echo "[X] wb_tools missing"
fi

awsCreds2() {
    local -a POSITIONAL
    local HELP USAGE FORCE ROOT FILENAME
    while (($# > 0)); do
        arg=$1 && shift
        case $arg in
            -h | --help) HELP=1 ;;
            -F | --force) FORCE=1 ;;
            -r | --root) ROOT=$1 && shift ;;
            -f | --file | --filename) FILENAME=$1 && shift ;;
            -*) _err "Unrecognized option: \"$arg\"" && USAGE=1 ;;
            *) POSITIONAL+=("$arg") ;;
        esac
    done

    set -- "${POSITIONAL[@]}"

    local USAGE_TEXT="${FUNCNAME[0]} [OPTIONS] PROFILE REGION"

    if [[ -v HELP ]]; then
        dedent <<< "
            Set required AWS environment variables, reauthenticating if necessary.
            Usage: $USAGE_TEXT

            Parameters:

            PROFILE             The Okta profile (to be passed to gimme-aws-creds).
            REGION              The AWS region to use.

            Options:

            -h | --help         Print this help output and return.
            -F | --force        Do not examine curent or cached credentials; always reload them.
            -r | --root ROOT    The directory root to read & write cached credential files from.
            -f | --file FILE    The specific filename to read and write cached credentials from.

            If --file is pointed to an existing profile file, PROFILE and REGION are not required.
            "
        return 0
    fi

    local name PROFILE REGION
    for name in PROFILE REGION; do
        (($# > 0)) || break
        eval "${name}=$1" && shift
    done

    if (($# != 0)); then
        _err "Too many parameters: $*"
        USAGE=1
    fi

    if [[ -v PROFILE && ! -v REGION ]]; then
        _err "PROFILE and REGION are mutually dependent"
        USAGE=1
    fi

    if [[ ! -v FILENAME && ! -v PROFILE ]]; then
        _err "Either --file or PROFILE and REGION are required"
        USAGE=1
    fi

    if [[ -v FILENAME && -v ROOT ]]; then
        _err "Options --root and --file are mutually exclusive"
        USAGE=1
    fi

    [[ -v USAGE ]] && throw "Usage: $USAGE_TEXT"

    local EXPLICIT_PARAMS
    [[ -v PROFILE && -v REGION ]] && EXPLICIT_PARAMS=1

    # if we weren't given an explicit filename, generate one
    if [[ ! -v FILENAME ]]; then
        # set a default ROOT directory if necessary
        ROOT="${ROOT:-$HOME/.aws}"
        [[ -d $ROOT ]] || throw "Profile root directory does not exist: $ROOT"

        FILENAME=$ROOT/${PROFILE:?}_${REGION:?}_profile
    fi

    # if we weren't told to force reauthentication with explicit parameters, try to read our file
    if [[ ! (-v FORCE && -v EXPLICIT_PARAMS) ]]; then

        # if we don't have explicit parameters and our file doesn't exist, return failure
        # if we don't have explicit parameters and our file is missing required values, return failure
        # if we *do* have explicit parameters, and they don't match our file, return failure
        # if we aren't being `--force`d, and our file's credentials aren't expired, return success

        # if our file exists, read it
        if [[ -f $FILENAME ]]; then
            source "$FILENAME"

            # if our file sets the appropriate parameter variables...
            if [[ -n ${AWS_OKTA_PROFILE-} && -n ${AWS_REGION-} ]]; then
                # if we were given explicit parameters, make sure they match our file
                if [[ -v EXPLICIT_PARAMS ]]; then
                    if [[ $PROFILE != "$AWS_OKTA_PROFILE" || $REGION != "$AWS_REGION" ]]; then
                        _err "Cached credentials do not match given PROFILE and REGION: $FILENAME"
                        _err "Use --force to overwrite"
                        return 1
                    fi
                else
                    # if we were *not* given explicit parameters, use the values from our file
                    local PROFILE=${AWS_OKTA_PROFILE:?}
                    local REGION=${AWS_REGION:?}
                fi

                if [[ -v FORCE ]]; then
                    # if we were told to force reauthentication, continue
                    true
                elif [[ ! -v AWS_SESSION_TOKEN ]]; then
                    # otherwise, if our file does not set required credential variables, continue to reauthentication
                    _log "Cached credentials appear invalid: $FILENAME"
                elif [[ -v AWS_CREDENTIAL_EXPIRATION && $AWS_CREDENTIAL_EXPIRATION < $(date --iso-8601=seconds) ]]; then
                    # otherwise, if our file's credentials appear to be expired, continue to reauthentication
                    _log "Cached credentials appear expired: $FILENAME"
                elif aws s3 ls &> /dev/null; then
                    # otherwise, if we can successfully list s3 buckets, return success
                    _log "Cached credentials appear valid (use --force to force reauthentication)"
                    _log "Assumed AWS profile: ${AWS_OKTA_PROFILE:?} (${AWS_REGION:?}): ${AWS_PROFILE:?}"
                    return 0
                fi

            elif [[ ! -v EXPLICIT_PARAMS ]]; then
                # if our file does not set required parameter variables, and we don't have explicit parameters, return failure
                _err "Profile file seems to be missing required values: $FILENAME"
                _err "Pass PROFILE and REGION to reauthenticate"
                return 1
            fi

        elif [[ ! -v EXPLICIT_PARAMS ]]; then
            # if our file doesn't exist, and we don't have explicit parameters, return failure
            _err "Profile file does not exist: $FILENAME"
            _err "Pass PROFILE and REGION to reauthenticate"
            return 1
        fi
    fi

    _log "Reauthenticating with PROFILE=$PROFILE, REGION=$REGION"

    # perform request
    local JSON_RESPONSE
    JSON_RESPONSE=$(gimme-aws-creds --profile="$PROFILE" --output-format=json) || throw "Failed to gather credentials"

    local AWS_PROFILE
    AWS_PROFILE=$(jq -r '.profile.name' <<< "$JSON_RESPONSE") || {
        echo >&2 "[X] Response seems invalid"
        echo >&2 "$JSON_RESPONSE"
        return 1
    }

    _log "Caching credentials to $FILENAME"

    jq -r --arg okta_profile "$PROFILE" --arg region "$REGION" '
        {
            "aws_profile": .profile.name,
            "aws_okta_profile": $okta_profile,
            "aws_region": $region,
            "aws_credential_expiration": .credentials.expiration
        } + ( .credentials | del(.expiration) )
        | to_entries[]
        | .key |= ascii_upcase
        | .value |= @sh
        | "export \(.key)=\(.value)"
        ' <<< "$JSON_RESPONSE" > "$FILENAME"

    # # write file
    # dedent > "$FILENAME" <<< "
    #     export AWS_OKTA_PROFILE="$PROFILE"
    #     export AWS_PROFILE="$AWS_PROFILE"
    #     export AWS_REGION="$REGION"
    #     export AWS_ACCESS_KEY_ID="$(jq -r '.credentials.aws_access_key_id' <<< "$JSON_RESPONSE")"
    #     export AWS_SECRET_ACCESS_KEY="$(jq -r '.credentials.aws_secret_access_key' <<< "$JSON_RESPONSE")"
    #     export AWS_SESSION_TOKEN="$(jq -r '.credentials.aws_session_token' <<< "$JSON_RESPONSE")"
    #     export AWS_SECURITY_TOKEN="$(jq -r '.credentials.aws_security_token' <<< "$JSON_RESPONSE")"
    #     export AWS_CREDENTIAL_EXPIRATION="$(jq -r '.credentials.expiration' <<< "$JSON_RESPONSE")"
    #     "

    chmod 600 "$FILENAME"

    source "$FILENAME"
    _log "Assumed AWS profile: ${AWS_OKTA_PROFILE:?} (${AWS_REGION:?}): ${AWS_PROFILE:?}"
}
