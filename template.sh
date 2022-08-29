#! /usr/bin/env nix-shell
#! nix-shell -i bash
#! nix-shell --pure
#! nix-shell --keep ENV1 --keep ENV2 --keep DEBUG
#! nix-shell -p hello

# https://vaneyckt.io/posts/safer_bash_scripts_with_set_euxo_pipefail
set -Eeuo pipefail

# cd to script location
cd "$(dirname "${BASH_SOURCE[0]}")"

source lib.sh


# Configure your variables and parameters here.
# We destinguish between variables and attributes and interprete the key of as 2-dim arrays.
#   -> In our case: e1, e2, p1, p2 and b are our variables
#   -> In our case: arg, value, short, required, name, type and pos are our attributes
# The scritp assumes the 2-dim array keys to be separated by a comme (,).
# Variables are checked by searching all arguments for the representing arg or its short version.
#   -> In our case: To check e1, we search for --env1 or -e1, because we defined the 
#                   arg with [e1,arg]="--env1" and its short version with [e1,short]="-e1"
# Requriered parameters are checked and a usful error is provided if they are omitted.
# If your value can be provided by an environment variable, you have to define the environment value.
#   -> In our case: [e1,value]="{ENV1:-}" and [e2,value]="${ENV2:-}"
# If you don't want it to be set by an environment variable (so it can only be configured by parameters),
# you must not (!) define it for the build in evaluation to work.
#   -> In our case: [p1,value], [p2,value] and [b,value] are not defined in the array
declare -A template_options=(
    [e1,arg]="--env1" [e1,value]="${ENV1:-}" [e1,short]="-e1" [e1,required]=true  [e1,name]="ENV1"
    [e2,arg]="--env2" [e2,value]="${ENV2:-}" [e2,short]="-e2" [e2,required]=false [e2,name]="ENV2"
    [p1,arg]="--par1"                        [p1,short]="-p1" [p1,required]=true  [p1,name]="PAR1"
    [p2,arg]="--par2"                        [p2,short]="-p2" [p2,required]=false [p2,name]="PAR2"       [p2,pos]=2
    [b,arg]="--bool"                         [b,short]="-b"   [b,required]=false  [b,name]="Bool Switch" [b,tpe]="bool"
)
# This will contain the resulting parameters of your command
declare -a template_params

# Define your usage and help message here
usage() (
    local script_name="${0##*/}"
    cat <<-USAGE

Explain what this script does and exit.
Describes the nix-shell parameter and provides template for scripts.


Usage and Examples
-----

- Print information about nix-shell parameters:
    $script_name


$(_generate_usage template_options)

USAGE
)

# Put your script logic here
run() (
    # Use all the parameter with the defined array template_params

    echo "nix-shell"
    echo "      -i: provides interpreter, here bash."
    echo "  --pure: only packeges provided by -p are available + environment is cleaned."
    echo "  --keep: propagade the provided environment variable ENV1 to the nix-shell."
    echo "      -p: provide space separated list of dependencies. Here gnu hello."
    echo "You can split up nix-shell parameters across lines."
    echo "The parameters will be merged"

    local paramstr="${template_params[@]}"
    hello -g "hello $paramstr"

    # Or access a dedicated variable by using get_args yourself
    # local -a p1_params
    # get_args p1_params "p1"
    # local paramstr="${p1_params[@]}"
    # hello -g "hello $paramstr"
)


# This is the base frame and it shouldn't be necessary to touch it
self() (
    declare -a args=( "$@" )
    if [[ "${1:-}" == "help" ]] || [[ "${1:-}" == "--help" ]]; then
        usage
    elif (check_requirements template_options args); then

        process_args template_options args template_params || _print_debug "Couldn't process args, terminated with $?"

        run
    else
        _print_debug "Requirements not met"
    fi

)

self "$@"
