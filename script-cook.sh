#! /usr/bin/env bash
set -Eeuo pipefail

if [[ "${SCRIPT_COOK_COMMON_LOADED:-}" != "true" ]]; then
    source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
fi
if [[ "${SCRIPT_COOK_IO_LOADED:-}" != "true" ]]; then
    source "$(dirname "${BASH_SOURCE[0]}")/lib/io.sh"
fi
if [[ "${SCRIPT_COOK_CHECK_LOADED:-}" != "true" ]]; then
    source "$(dirname "${BASH_SOURCE[0]}")/lib/check.sh"
fi
if [[ "${SCRIPT_COOK_ARGS_LOADED:-}" != "true" ]]; then
    source "$(dirname "${BASH_SOURCE[0]}")/lib/args.sh"
fi

unset test_assoc_array
if (( ${BASH_VERSINFO:-0} < 4 )) || (! declare -A test_assoc_array); then
    io::print_error "associative arrays not supported!"
    exit 1
fi

cook::usage() {
    local -rn cook_usage_options="$1"
    io::generate_usage cook_usage_options
}
cook::check() {
    local -n cook_check_requirements_options="$1"
    local -n cook_check_requirements_arg="$2"
    check::requirements cook_check_requirements_options cook_check_requirements_arg
}
cook::process() {
    local -n script_cook_options="$1"
    local -n script_cook_args="$2"
    local -n script_cook_params="$3"
    args::process script_cook_options script_cook_args script_cook_params
}
cook::get() {
    local -n cook_get_options="$1"
    local cook_get_arg="${2:-}"
    args::get cook_get_options cook_get_arg
}
cook::get_str() {
    args::get_str "$1"
}
cook::get_values() {
    local -n cook_get_values_options="$1"
    local cook_get_values_arg="${2:-}"
    args::get_values cook_get_values_options cook_get_values_arg
}
cook::get_values_str() {
    args::get_values_str "$1"
}
cook::array_from_str() {
    local -n cook_array_from_str_array="$1"
    local cook_array_from_str_str="$2"
    common::get_array_from_str cook_array_from_str_array "$cook_array_from_str_str"
}

cleanup() (
    io::print_debug_error "Error: (${1:-}) occurred on line ${2:-} in ${3:-}"
)

trap 'cleanup $? $LINENO ${BASH_SOURCE##*/}' ERR
