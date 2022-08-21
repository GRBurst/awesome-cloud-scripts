#! /usr/bin/env nix-shell
#! nix-shell -i bash
#! nix-shell --pure
#! nix-shell --keep AWS_PROFILE
#! nix-shell -p awscli2 aws-vault

# https://vaneyckt.io/posts/safer_bash_scripts_with_set_euxo_pipefail
set -Eeuo pipefail

# cd to script location
cd "$(dirname "${BASH_SOURCE[0]}")"

source .lib.sh

# Configure your parameters here. The provided 
declare -A template_aws_params=(
    [p,arg]="--profile" [p,value]="${AWS_PROFILE:-}" [p,short]="-p" [p,required]=true  [p,name]="aws profile"
)

# Define your usage and help message here
usage() (
    local script_name="${0##*/}"
    cat <<-USAGE

Template for AWS scripts."
Please have a look at template.sh as well."



Usage and Examples
-----

- Print information about aws script call:
    $script_name


Arguments and Environment
---------

Required environment:
  - AWS_PROFILE variable or argument -p | --profile

USAGE

    exit 1
)

configure() {
    while [ "${1:-}" != "" ]; do
        case $1 in
        -p | --profile)
            shift
            assign template_aws_params p ${1:-} || usage
            ;;
        -h | --help)
            shift
            usage
            ;;
        esac
        shift
    done
}

run() (
    str=$(translate_args template_aws_params)
    aws sts get-caller-identity $str
)

self() (
    declare -a args=$@
    if ! (check_requirements args template_aws_params) || [[ "${1:-}" == "help" ]]; then
        usage
    else
        if (($# > 0)); then
            configure $args
        fi

        run
    fi

)

self $@
