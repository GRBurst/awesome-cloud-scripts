#! /usr/bin/env nix-shell
#! nix-shell -i bash
#! nix-shell --pure
#! nix-shell --keep AWS_PROFILE
#! nix-shell -p awscli2 aws-vault jq fzf

set -Eeuo pipefail

help() (
    echo -e "\n~~~ Help for ${0##*/} ~~~"
    echo    "Return up to 60 emails that have registered in last x days."
    echo    "The first parameters determines the number of days to look back."
    echo    "Defaults to 1 week (7 days)."

    echo -e "\nExamples"
    echo    "- Return a list of emails that have registered in the last 7 days (default):"
    echo -e "    ${0##*/}\n"
    echo    "- Return a list of emails that have registered in the last 14 days:"
    echo -e "    ${0##*/} 14\n"

    echo    "Required environment:"
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

    user_pool="$(aws cognito-idp list-user-pools --max-results 60 | jq -r '.UserPools | .[] | [.Name, .Id] | @tsv' | fzf | cut -f2)"
    days=${1:-7}
    filter_date="$(date +%Y-%m-%d'T'%H:%M'Z' -d "$days days ago")"
    aws cognito-idp list-users --user-pool-id "$user_pool" --attributes-to-get "email" | jq --arg date "$filter_date" '.Users | .[] | select( $date < .UserCreateDate) | .Attributes | .[].Value' | awk '{printf "%d: %s\n",NR,$0}'
)

self $@
