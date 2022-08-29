#! /usr/bin/env nix-shell
#! nix-shell -i bash
#! nix-shell --pure
#! nix-shell --keep AWS_PROFILE --keep DEBUG
#! nix-shell -p awscli2 aws-vault

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

Template for AWS scripts.
Please have a look at template.sh as well.


Usage and Examples
-----

- Print information about aws script call:
    $script_name


$(_generate_usage template_aws_options)

USAGE
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
    if [[ "${1:-}" == "help" ]] || [[ "${1:-}" == "--help" ]]; then
        usage
    elif (check_requirements template_aws_options args); then

        process_args template_aws_options args template_aws_params || _print_debug "Couldn't process args, terminated with $?"

        run
    else
        _print_debug "Requirements not met"
    fi

)

self "$@"
