#! /usr/bin/env nix-shell
#! nix-shell -i bash
#! nix-shell --pure
#! nix-shell --keep ENV1 --keep ENV2
#! nix-shell -p hello

# https://vaneyckt.io/posts/safer_bash_scripts_with_set_euxo_pipefail
set -Eeuo pipefail

# cd to script location
cd "$(dirname "${BASH_SOURCE[0]}")"

source .lib.sh


# Configure your parameters here.
# If it can be set by an env, you have to define the value (see [e1,value] and [e2,value]) and if it
# can only be configured by parameters, you must not define it (e.g. [p1,value] and [p2,value]).
declare -A template_options=(
    [e1,arg]="--env1" [e1,value]="${ENV1:-}" [e1,short]="-e1" [e1,required]=true  [e1,name]="ENV1"
    [e2,arg]="--env2" [e2,value]="${ENV2:-}" [e2,short]="-e2" [e2,required]=false [e2,name]="ENV2"
    [p1,arg]="--par1"                        [p1,short]="-p1" [p1,required]=true  [p1,name]="PAR1"
    [p2,arg]="--par2"                        [p2,short]="-p2" [p2,required]=false [p2,name]="PAR2"
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

    exit 1
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
    if [[ "${1:-}" == "help" ]] || [[ "${1:-}" == "--help" ]] || ! (check_requirements args template_options); then
        usage
    else

        process_args args template_options template_params

        run
    fi

)

self "$@"
