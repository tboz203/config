#!/bin/bash

# TODO: ensure we're sourced, not executed
# TODO: real argument parsing

[[ $# -eq 2 ]] || {
    echo "Usage: awsCreds2 PROFILE REGION"
    return 1
}

OKTA_PROFILE=$1
REGION=$2

# TODO: check for valid existing credentials
# TODO: check gimme-aws-creds version (or just acceptable cli options)

FILENAME="$HOME/.${OKTA_PROFILE}_profile"
JSON_RESPONSE=$(gimme-aws-creds --profile="${OKTA_PROFILE}" --output-format=json)
AWS_PROFILE=$(jq -r '.profile.name' <<< "$JSON_RESPONSE")

cat << EOF > "$FILENAME"
export AWS_OKTA_PROFILE="$OKTA_PROFILE"
export AWS_DEFAULT_PROFILE="$AWS_PROFILE"
export AWS_PROFILE="$AWS_PROFILE"
export AWS_REGION="$REGION"
export AWS_ACCESS_KEY_ID="$(jq -r '.credentials.aws_access_key_id' <<< "$JSON_RESPONSE")"
export AWS_SECRET_ACCESS_KEY="$(jq -r '.credentials.aws_secret_access_key' <<< "$JSON_RESPONSE")"
export AWS_SESSION_TOKEN="$(jq -r '.credentials.aws_session_token' <<< "$JSON_RESPONSE")"
export AWS_SECURITY_TOKEN="$(jq -r '.credentials.aws_security_token' <<< "$JSON_RESPONSE")"
export AWS_CREDENTIAL_EXPIRATION="$(jq -r '.credentials.expiration' <<< "$JSON_RESPONSE")"
EOF

source "$FILENAME"
chmod 600 "$FILENAME"

echo "Assumed AWS profile: $OKTA_PROFILE - $AWS_PROFILE"
