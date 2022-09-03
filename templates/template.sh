#! /usr/bin/env nix-shell
#! nix-shell -i bash
#! nix-shell -p hello
#! nix-shell --pure
#! nix-shell --keep ENV1 --keep ENV2 --keep DEBUG
# add '#' for the 2 shebangs above after finishing development of the script.

set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../script-cook.sh"

# This will contain the resulting parameters of your command
declare -a params


############################################
########## BEGIN OF CUSTOMISATION ##########
############################################

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
declare -A options=(
    [e1,arg]="--env1" [e1,value]="${ENV1:-}" [e1,short]="-e1" [e1,required]=true  [e1,name]="ENV1"
    [e2,arg]="--env2" [e2,value]="${ENV2:-}" [e2,short]="-e2" [e2,required]=false [e2,name]="ENV2"
    [p1,arg]="--par1"                        [p1,short]="-p1" [p1,required]=true  [p1,name]="PAR1"
    [p2,arg]="--par2"                        [p2,short]="-p2" [p2,required]=false [p2,name]="PAR2"       [p2,pos]=2
    [p3,arg]="-p3"                                            [p3,required]=false [p3,name]="PAR1"
    [b,arg]="--bool"                         [b,short]="-b"   [b,required]=false  [b,name]="Bool Switch" [b,tpe]="bool"
)

# Define your usage and help message here
usage() (
    local script_name="${0##*/}"
    cat <<-USAGE
Explain what this script does and exit.
Describes the nix-shell parameter and provides template for scripts.


Usage and Examples
---------

- Print information about nix-shell parameters:
    $script_name


$(io::generate_usage options)
USAGE
)

# Put your script logic here
run() (
    echo "nix-shell"
    echo "      -i: provides interpreter, here bash."
    echo "  --pure: only packeges provided by -p are available + environment is cleaned."
    echo "  --keep: propagade the provided environment variable ENV1 to the nix-shell."
    echo "      -p: provide space separated list of dependencies. Here gnu hello."
    echo "You can split up nix-shell parameters across lines."
    echo "The parameters will be merged"

    # Access a dedicated variable by using get_args yourself
    local -a p1_params
    args::get p1_params "p1"
    hello -g "hello ${p1_params[*]}"

    hello -g "hello $(args::get_str p1)"

    # Or use all the parameter with the defined array params
    hello -g "hello ${params[*]}"

)


############################################
########### END OF CUSTOMISATION ###########
############################################

# This is the base frame and it shouldn't be necessary to touch it
self() (
    declare -a args=( "$@" )
    if [[ "${1:-}" == "help" ]] || [[ "${1:-}" == "--help" ]]; then
        usage
    elif (check::requirements options args); then

        process_args options args params || io::print_debug "Couldn't process args, terminated with $?"

        run
    else
        io::print_debug "Requirements not met"
    fi

)

self "$@"
