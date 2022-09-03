#! /usr/bin/env nix-shell
#! nix-shell -i bash
#! nix-shell -p awscli2 aws-vault
#! nix-shell --pure
#! nix-shell --keep AWS_PROFILE --keep DEBUG
# add '#' for the 2 shebangs above after finishing development of the script.

# https://vaneyckt.io/posts/safer_bash_scripts_with_set_euxo_pipefail
set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../script-cook.sh"

# This will contain the resulting parameters of your command
declare -a params


############################################
########## BEGIN OF CUSTOMISATION ##########
############################################

# Configure your parameters here
declare -A options=(
    [p,arg]="--profile" [p,value]="${AWS_PROFILE:-}" [p,short]="-p" [p,required]=true [p,name]="aws profile"
)

# Define your usage and help message here
usage() (
    local script_name="${0##*/}"
    cat <<-USAGE
Template for AWS scripts.
Please have a look at template.sh as well.


Usage and Examples
---------

- Print information about aws script call:
    $script_name


$(cook::usage options)
USAGE
)

# Put your script logic here
run() (
    # Use all the parameter with the defined array params
    # aws sts get-caller-identity "${params[@]}"

    # Or access a dedicated variable array by using get_args yourself
    # local -a p_params
    # get_args p_params "p"
    # aws sts get-caller-identity "${p_params[@]}"

    # Or access a dedicated arg string (don't quote subshell)
    aws sts get-caller-identity $(cook::get_str p)

    # Or store the arg string in a variable before
    # local p="$(get_args_str p)"
    # aws sts get-caller-identity $p
)


############################################
########### END OF CUSTOMISATION ###########
############################################

# This is the base frame and it shouldn't be necessary to touch it
self() (
    declare -a args=( "$@" )
    if [[ "${1:-}" == "help" ]] || [[ "${1:-}" == "--help" ]]; then
        usage
    elif (cook::check_requirements options args); then

        cook::process options args params

        run
    fi

)

self "$@"
