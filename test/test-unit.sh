#! /usr/bin/env bash

set -Eeuo pipefail

declare script_path="$(dirname "${BASH_SOURCE[0]}")"
source "$script_path/../script-cook.sh"

declare -A options=(
    [n,arg]="--name"            [n,short]="-n" [n,required]=true  [n,name]="name"
    [e,arg]="--expected-result" [e,short]="-e" [e,required]=true  [e,name]="result message"
    [p,arg]="--parameters"      [p,short]="-p" [p,required]=false [p,name]="parameters"
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
    --name "missing par1 par" \\
    --expected-result "[ERROR] PAR1 parameter required but not provided."

- Run the script with all required parameters:
    $script_name \\
    --name "template" \\
    --expected-result "hello --par1 foo --env1 bar" \\
    --parameters "-p1 foo -e1 bar"


$(_generate_usage options)
USAGE
)


# Put your script logic here
run() (

    fail()      ( echo -e "\e[31m[   FAIL] $1 failed\e[0m" )
    success()   ( echo -e "\e[32m[SUCCESS] $1 succeeded\e[0m" )

    local name msg pars
    name="$(args::get_values_str n)"
    msg="$(args::get_values_str e)"
    pars="$(args::get_values_str p)"
 
    local -a parameter_args
    common::get_array_from_str parameter_args "$pars"

    [[ "$($script_path/../templates/template.sh "${parameter_args[@]}" 2>&1 | tail -n 1)" == *"$msg"* ]] && success "$name" || fail "$name"
)


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
