#! /usr/bin/env bash

set -Eeuo pipefail

declare script_path="$(dirname "${BASH_SOURCE[0]}")"
source "$script_path/../bin/script-cook.sh"

declare -A inputs=(
    [d,param]="--desc"            [d,short]="-d" [d,required]=true  [d,desc]="description"
    [e,param]="--expected-result" [e,short]="-e" [e,required]=true  [e,desc]="result message"
    [p,param]="--parameters"      [p,short]="-p" [p,required]=false [p,desc]="parameters"
)
# This will contain the resulting parameters of your command
declare -a params

# Define your usage and help message here
usage() (
    local script_name="${0##*/}"
    cat <<-USAGE
Runs template.sh with provided parameters and test for the expected result.


Usage and Examples
---------

- Run the script without parameters:
    $script_name \\
    --desc "missing par1 par" \\
    --expected-result "[ERROR] PAR1 parameter required but not provided."

- Run the script with all required parameters:
    $script_name \\
    --desc "template" \\
    --expected-result "hello --par1 foo --env1 bar" \\
    --parameters "-p1 foo -e1 bar"


$(cook::usage inputs)
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


# This is the base frame and it shouldn't be necessary to touch it
self() (
    declare -a args=( "$@" )
    if [[ "${1:-}" == "help" ]] || [[ "${1:-}" == "--help" ]]; then
        usage
    elif (cook::check inputs args); then

        cook::process inputs args params && run
        cook::clean
    fi

)

self "$@"
