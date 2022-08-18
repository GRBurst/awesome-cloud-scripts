#! /usr/bin/env nix-shell
#! nix-shell -i bash
#! nix-shell --pure
#! nix-shell --keep AWS_PROFILE
#! nix-shell -p awscli2 aws-vault jq fzf xclip

set -Eeuo pipefail

help() (
    echo -e "\n~~~ Help for ${0##*/} ~~~"
    echo    "${0##*/} consists of 2 parts:"
    echo    "1. Let user choose a secret by name."
    echo    "2. Get the secret and copy it to your clipboard."

    echo -e "\nExamples"
    echo    "- Choose and copy an aws secret to your clipboard:"
    echo -e "    ${0##*/}\n"

    echo -e "Required environment:"
    echo    "  - AWS_PROFILE variable"
    exit 1
)

requirements() (
    if [[ -z ${AWS_PROFILE+x} ]]; then
        echo "AWS_PROFILE is not set. Aborting."
        return 1
    fi
    return 0
)

self() (
    if ! requirements || ( [[ $# -ge 1 ]] && [[ "$1" == "help" ]] ); then
        help
    fi

    secret_name="$(aws secretsmanager list-secrets | jq -r '.SecretList | .[].Name' | fzf)"
    aws secretsmanager get-secret-value --version-stage AWSCURRENT --secret-id "$secret_name" | jq -r '.SecretString | fromjson | .password' | xclip
)

self $@
