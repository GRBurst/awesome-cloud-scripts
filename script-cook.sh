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

process_args() {
    local -n process_options="$1"
    local -n process_args="$2"
    local -n process_params="$3"

    args::configure process_options process_args || io::print_debug "configure terminated with $?"
    args::translate process_options              || io::print_debug "translate terminated with $?"
    args::get       process_params               || io::print_debug "get_args terminated with $?"
}

cleanup() (
    >&2 echo "Error: (${1:-}) occurred on line ${2:-} in ${3:-}"
)

trap 'cleanup $? $LINENO ${BASH_SOURCE##*/}' ERR
