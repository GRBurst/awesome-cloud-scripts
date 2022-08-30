#! /usr/bin/env bash

# https://vaneyckt.io/posts/safer_bash_scripts_with_set_euxo_pipefail
set -Eeuo pipefail

# cd to script location
cd "$(dirname "${BASH_SOURCE[0]}")"

source lib.sh

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

Test this library.


Usage and Examples
-----

- Print information about nix-shell parameters:
    $script_name


$(_generate_usage options)

USAGE
)


# Put your script logic here
run() (

    fail()      ( echo -e "\e[31m[   FAIL] $1 failed\e[0m" )
    success()   ( echo -e "\e[32m[SUCCESS] $1 succeeded\e[0m" )

    local name="$(get_values_str n)"
    local msg="$(get_values_str e)"
    local pars="$(get_values_str p)"

    [[ "$(./template.sh $pars | tail -n 1)" == *"$msg"* ]] && success "$name" || fail "$name"
)


# This is the base frame and it shouldn't be necessary to touch it
self() (
    declare -a args=( "$@" )
    if [[ "${1:-}" == "help" ]] || [[ "${1:-}" == "--help" ]]; then
        usage
    elif (check_requirements options args); then

        process_args options args params || _print_debug "Couldn't process args, terminated with $?"

        run
    else
        _print_debug "Requirements not met"
    fi

)

self "$@"
