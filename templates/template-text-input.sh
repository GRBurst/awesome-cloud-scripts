#! /usr/bin/env nix-shell
#! nix-shell -i bash
#! nix-shell -p hello
#! nix-shell --keep ENV1 --keep ENV2 --keep DEBUG
#! nix-shell --pure
# add '#' for the line / shebangs above after finishing development of the script.

set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../bin/script-cook.sh"

# This will contain the resulting parameters of your command
declare -a params
declare -A inputs

############################################
########## BEGIN OF CUSTOMISATION ##########
############################################

# Configure your variables and parameters here.
# We destinguish between variables and attributes and interprete the key of as 2-dim arrays / matrix.
#   -> In our case: e1, e2, p1, p2 and f are our variables
#   -> In our case: arg, value, short, required, desc, tpe and arity are our attributes
# Variables are checked by searching all arguments for the representing arg or its short version.
#   -> In our case: To check e1, we search for --env1 or -e1, because we defined the 
#                   arg with [e1,param]="--env1" and its short version with [e1,short]="-e1"
# Requriered parameters are checked and a usful error is provided if they are omitted.
# If your value can be provided by an environment variable, you have to define the environment value.
#   -> In our case: [e1,value]="{ENV1:-}" and [e2,value]="${ENV2:-}"
# If you don't want it to be set by an environment variable (so it can only be configured by parameters),
# you must not (!) define it for the build in evaluation to work.
#   -> In our case: [p1,value], [p2,value] and [f,value] are not defined in the array
declare -r inputs_str=$(cat <<INPUTSTR
# delimiter is the first character in your table to split the variables.
# here, it is '|', because it is the first character in the column name row,
# which is starting with ' | id | tpe | ... '
# -  | named  | -      | -     | -     | false    | 1     | -      | <-- default values
| id | tpe    | param  | short | value | required | arity | desc   |
# -------------------------------------------------------------------- #
| e1 |        | --env1 | -e1   | ENV1  | true     |       | ENV1   |
| e2 |        | --env2 | -e2   | ENV2  |          |       | ENV2   |
| p1 |        | --par1 | -p1   |       | true     |       | PAR1   |
| p2 |        | --par2 | -p2   |       |          | 2     | PAR2   |
| p3 |        | -p 3   |       |       |          |       | PAR3   |
|  f | flag   | --flag | -f    |       |          |       | Switch |
INPUTSTR
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


$(cook::usage inputs)
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
    cook::get p1_params p1
    hello -g "hello ${p1_params[*]}"

    hello -g "hello $(cook::get_str p1)"

    # Or use all the parameter with the defined array params
    declare -p params
    hello -g "hello ${params[*]}"

)


###########################################
########## END OF CUSTOMISATION ###########
###########################################

# This is the base frame and it shouldn't be necessary to touch it
self() (
    declare -a args=( "$@" )

    if [[ -n "${inputs_str:+set}" ]]; then
        cook::parse inputs "$inputs_str"
    fi

    if [[ "${1:-}" == "help" ]] || [[ "${1:-}" == "--help" ]]; then
        usage
    elif [[ "${1:-}" == "version" ]] || [[ "${1:-}" == "--version" ]]; then
        echo "1.0.0"
        return 0
    else
        cook::process inputs args params && run
        cook::clean
    fi
)

self "$@"
