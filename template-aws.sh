#! /usr/bin/env nix-shell
#! nix-shell -i bash
#! nix-shell --pure
#! nix-shell --keep AWS_PROFILE
#! nix-shell -p awscli2 aws-vault

# nix-shell -p (import ./deps.nix)
# nix-shell ./deps.nix

# https://vaneyckt.io/posts/safer_bash_scripts_with_set_euxo_pipefail
set -Eeuo pipefail

# cd to script location
cd "$(dirname "${BASH_SOURCE[0]}")"

source .lib.sh


# Configure your parameters here. The provided 
declare -A template_aws_options=(
    [p,arg]="--profile" [p,value]="${AWS_PROFILE:-}" [p,short]="-p" [p,required]=true [p,name]="aws profile"
)
# This will contain the resulting parameters of your command
declare -a template_aws_params

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

# Put your script logic here
run() (
    # Use all the parameter with the defined array template_aws_params
    # echo "aws sts get-caller-identity ${template_aws_params[@]}"
    # aws sts get-caller-identity "${template_aws_params[@]}"

    # Or access a dedicated variable by using get_args yourself
    local -a p_params
    get_args p_params "p"
    # echo "aws sts get-caller-identity ${p_params[@]}"
    aws sts get-caller-identity "${p_params[@]}"
)


# This is the base frame and it shouldn't be necessary to touch it
self() (
    declare -a args=( "$@" )
    if ! (check_requirements args template_aws_options) || [[ "${1:-}" == "help" ]]; then
        usage
    else

        process_args args template_aws_options template_aws_params

        run

    fi

)

self "$@"
