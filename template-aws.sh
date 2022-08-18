#! /usr/bin/env nix-shell
#! nix-shell -i bash
#! nix-shell --pure
#! nix-shell --keep AWS_PROFILE
#! nix-shell -p awscli2 aws-vault

set -Eeuo pipefail

script_name="${0##*/}"

help() (
    echo -e "\n~~~ Help for $script_name ~~~"
    echo    "Template for AWS scripts."
    echo    "Please have a look at template.sh as well."

    echo -e "\nExamples"
    echo    "- Print information about aws script call:"
    echo -e "    $script_name\n"

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

    aws sts get-caller-identity
)

self $@
