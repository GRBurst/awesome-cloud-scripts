#! /usr/bin/env bash
set -Eeuo pipefail

if [[ "${SCRIPT_COOK_COMMON_LOADED:-}" != "true" ]]; then
    source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
else
    io::print_debug "SCRIPT_COOK_COMMON_LOADED already loaded"
fi
if [[ "${SCRIPT_COOK_IO_LOADED:-}" != "true" ]]; then
    source "$(dirname "${BASH_SOURCE[0]}")/../lib/io.sh"
else
    io::print_debug "SCRIPT_COOK_IO_LOADED already loaded"
fi
if [[ "${SCRIPT_COOK_CHECK_LOADED:-}" != "true" ]]; then
    source "$(dirname "${BASH_SOURCE[0]}")/../lib/check.sh"
else
    io::print_debug "SCRIPT_COOK_CHECK_LOADED already loaded"
fi
if [[ "${SCRIPT_COOK_ARGS_LOADED:-}" != "true" ]]; then
    source "$(dirname "${BASH_SOURCE[0]}")/../lib/args.sh"
else
    io::print_debug "SCRIPT_COOK_ARGS_LOADED already loaded"
fi

unset test_assoc_array
if (( ${BASH_VERSINFO:-0} < 4 )) || (! declare -A test_assoc_array); then
    io::print_error "associative arrays not supported!"
    exit 1
fi

cook::usage() {
    local -rn cook_usage_inputs="$1"
    io::generate_usage cook_usage_inputs
}
cook::check() {
    local -n cook_check_requirements_inputs="$1"
    local -n cook_check_requirements_arg="$2"
    check::requirements cook_check_requirements_inputs cook_check_requirements_arg
}
cook::process() {
    local -n script_cook_inputs="$1"
    local -n script_cook_args="$2"
    local -n script_cook_params="$3"

    if (check::requirements script_cook_inputs script_cook_args); then
        args::process script_cook_inputs script_cook_args script_cook_params
    else
        return 1
    fi
}
cook::get() {
    local -n cook_get_inputs="$1"
    local cook_get_arg="${2:-}"
    args::get cook_get_inputs "$cook_get_arg"
}
cook::get_str() {
    args::get_str "$1"
}
cook::get_values() {
    local -n cook_get_values_inputs="$1"
    local cook_get_values_arg="${2:-}"
    args::get_values cook_get_values_inputs "$cook_get_values_arg"
}
cook::get_values_str() {
    args::get_values_str "$1"
}
cook::array_from_str() {
    local -n cook_array_from_str_array="$1"
    local cook_array_from_str_str="$2"
    common::get_array_from_str cook_array_from_str_array "$cook_array_from_str_str"
}
cook::parse() {
    local -n cook_parse_inputs_ref="$1"
    local -r cook_parse_inputs_str="$2"
    io::parse cook_parse_inputs_ref "$cook_parse_inputs_str"
}

cook::clean() {
    unset SCRIPT_COOK_COMMON_LOADED
    unset SCRIPT_COOK_IO_LOADED
    unset SCRIPT_COOK_CHECK_LOADED
    unset SCRIPT_COOK_ARGS_LOADED
}
cook::on_err() {
    cook::clean
    io::print_debug_error "Error: (${1:-}) occurred on line ${2:-} in ${3:-}"
}

trap 'cook::on_err $? $LINENO ${BASH_SOURCE##*/}' ERR
