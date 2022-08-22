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

# Configure your parameters here. The provided 
declare -A template_params=(
    [e1,arg]="--env1" [e1,value]="${ENV1:-}" [e1,short]="-e1" [e1,required]=true  [e1,name]="ENV1"
    [e2,arg]="--env2" [e2,value]="${ENV2:-}" [e2,short]="-e2" [e2,required]=false [e2,name]="ENV2"
    [p1,arg]="--par1"                        [p1,short]="-p1" [p1,required]=true  [p1,name]="PAR1"
    [p2,arg]="--par2"                        [p2,short]="-p2" [p2,required]=false [p2,name]="PAR2"
    [b,arg]="--bool"                         [b,short]="-b"   [b,required]=false  [b,name]="Bool Switch"
)
# We will add boolean switches like --bool to this
declare -a template_bool_switches

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


Arguments and Environment
---------

Required arguments:
  -p1 | --par1

Optional arguments:
  -p2 | --par2

Required environment:
  - ENV1 variable or argument -e1 | --env1

Optional environment:
  - ENV2 variable or argument -e2 | --env2

USAGE

    exit 1
)

configure() {
    while [ "${1:-}" != "" ]; do
        case $1 in
        -e1 | --env1)
            shift
            assign template_params e1 ${1:-} || usage
            ;;
        -e2 | --env2)
            shift
            assign template_params e2 ${1:-} || usage
            ;;
        -p1 | --par1)
            shift
            assign template_params p1 ${1:-} || usage
            ;;
        -p2 | --par2)
            shift
            assign template_params p2 ${1:-} || usage
            ;;
        -b | --bool)
            # this is a boolean switch without a value
            template_bool_switches+=( "--bool" )
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
    echo "nix-shell"
    echo "      -i: provides interpreter, here bash."
    echo "  --pure: only packeges provided by -p are available + environment is cleaned."
    echo "  --keep: propagade the provided environment variable ENV1 to the nix-shell."
    echo "      -p: provide space separated list of dependencies. Here gnu hello."
    echo "You can split up nix-shell parameters across lines."
    echo "The parameters will be merged"

    str=$(translate_args template_params template_bool_switches)
    hello -g "hello $str"
)


self() (
    declare -a args=$@
    if ! (check_requirements args template_params) || [[ "${1:-}" == "help" ]]; then
        usage
    else
        if (($# > 0)); then
            configure $args
        fi

        run
    fi

)

self $@
