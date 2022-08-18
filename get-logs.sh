#! /usr/bin/env nix-shell
#! nix-shell -i bash
#! nix-shell --pure
#! nix-shell --keep AWS_PROFILE
#! nix-shell -p awscli2 aws-vault awslogs fzf

set -Eeuo pipefail

script_name="${0##*/}"

help() (
    echo -e "\n~~~ Help for $script_name ~~~"
    echo    "Choose and get aws logs of a chosen log group."

    echo -e "\nExamples"
    echo    "- Choose and get aws logs:"
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

    group=$(awslogs groups | fzf)
    if [ -n "$group" ]
    then
        awslogs get --watch $group --no-group --no-stream
    fi
)

self $@
