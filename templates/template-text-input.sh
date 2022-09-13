#! /usr/bin/env nix-shell
#! nix-shell -i bash
#! nix-shell -p hello
#! nix-shell --keep ENV1 --keep ENV2 --keep DEBUG
#! nix-shell --pure
# add '#' for the line / shebangs above after finishing development of the script.

set -Eeuo pipefail
declare -r VERSION="1.0.0"

declare -r script_path="$(dirname "${BASH_SOURCE[0]}")"
# This is for compatibility to run it without a nix-shell
if command -v script-cook.sh &> /dev/null; then
    source script-cook.sh
else
    source "$script_path/../script-cook/bin/script-cook.sh"
fi

declare -A inputs  # Define your inputs below
declare inputs_str # Alternatively define them in a string matrix
declare usage      # Define your usage + examples below
declare -a params  # Holds all input parameter

############################################
########## BEGIN OF CUSTOMISATION ##########
############################################

# Configure your inputs, parameters and arguments here.
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
inputs_str=$(cat <<INPUTSTR
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

# Define your usage and help message here.
# The script will append a generated parameter help message based on your inputs.
# This will be printed if the `--help` or `-h` flag is used.
usage=$(cat <<-USAGE
Explain what this script does and exit.
Describes the nix-shell parameter and provides template for scripts.

Usage and Examples
---------

- Print information about nix-shell parameters:
    $(cook::name) --env1 foo -p1 bar
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
    hello -g "hello ${params[*]}"

)


###########################################
########## END OF CUSTOMISATION ###########
###########################################

readonly usage inputs_str

# We are passing the whole data to cook::run, where
# 1. run is your function defined above
# 2. inputs (array) or inputs_str (string) are the possible inputs you defined
# 3. params is the resulting array containing all inputs provided
# 4. usage is your usage string and will be enriched + printed on help
# 5. $@ is the non-checked input for the script
cook::run run inputs params "${inputs_str:-}" "${usage:-}" "$@"
