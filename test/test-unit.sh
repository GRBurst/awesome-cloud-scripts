#! /usr/bin/env nix-shell
#! nix-shell -i bash
#! nix-shell -p nix hello
#! nix-shell --keep ENV1 --keep ENV2 --keep DEBUG
#! nix-shell --pure

set -Eeuo pipefail
declare -r VERSION="1.0.0"

declare script_path="$(dirname "${BASH_SOURCE[0]}")"
source "$script_path/../bin/script-cook.sh"

declare -A inputs  # Define your inputs below
declare inputs_str # Alternatively define them in a string matrix
declare usage      # Define your usage + examples below
declare -a params  # Holds all input parameter

############################################
########## BEGIN OF CUSTOMISATION ##########
############################################

inputs=(
    [d,param]="--desc"            [d,short]="-d" [d,required]=true  [d,desc]="description"
    [e,param]="--expected-result" [e,short]="-e" [e,required]=true  [e,desc]="result message"
    [p,param]="--parameters"      [p,short]="-p" [p,required]=false [p,desc]="parameters"
)

# Define your usage and help message here.
# The script will append a generated parameter help message based on your inputs.
# This will be printed if the `--help` or `-h` flag is used.
usage=$(cat <<-USAGE
Runs template.sh with provided parameters and test for the expected result.

Usage and Examples
---------

- Run the script without parameters:
    test-unit.sh \\
    --desc "missing par1 par" \\
    --expected-result "[ERROR] PAR1 parameter required but not provided."

- Run the script with all required parameters:
    test-unit.sh \\
    --desc "template" \\
    --expected-result "hello --par1 foo --env1 bar" \\
    --parameters "-p1 foo -e1 bar"
USAGE
)


# Put your script logic here
run() (

    fail()      ( echo -e "\e[31m[   FAIL] $1 failed\e[0m" )
    success()   ( echo -e "\e[32m[SUCCESS] $1 succeeded\e[0m" )

    local desc msg pars
    desc="$(cook::get_values_str d)"
    msg="$(cook::get_values_str e)"
    pars="$(cook::get_values_str p)"

    local -a parameter_args
    cook::array_from_str parameter_args "$pars"

    [[ "$($script_path/../templates/template.sh "${parameter_args[@]}" 2>&1 | tail -n 1)" == *"$msg"* ]] && success "$desc" || fail "$desc"

    [[ "$($script_path/../templates/template-text-input.sh "${parameter_args[@]}" 2>&1 | tail -n 1)" == *"$msg"* ]] && success "$desc" || fail "$desc"
)


###########################################
########## END OF CUSTOMISATION ###########
###########################################
readonly usage inputs_str
cook::run run inputs params "${inputs_str:-}" "${usage:-}" "$@"
