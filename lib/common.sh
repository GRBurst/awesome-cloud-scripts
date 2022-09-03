#! /usr/bin/env bash
set -Eeuo pipefail

declare -xr SCRIPT_COOK_COMMON_LOADED=true

common::get_keys_matrix() {
    local -rn _get_keys_matrix_assoc="$1"
    local -n _get_keys_matrix_rows="$2"
    local -n _get_keys_matrix_cols="$3"
    # We create two arrays for the rows and column keys that doesn't contain duplicates
    for var in "${!_get_keys_matrix_assoc[@]}"; do
        IFS=',' read -ra _key_arr <<< "${var}"
        if [[ -n "${_key_arr[0]+unset}" ]]; then
            _get_keys_matrix_rows["${_key_arr[0]}"]=1
        fi
        if [[ -n "${_key_arr[1]+unset}" ]]; then
            _get_keys_matrix_cols["${_key_arr[1]}"]=1
        fi
    done
}

common::get_variable_from_param() (
    local -rn get_variable_options="$1"
    local param="$2"
    local res=""

    declare -A rows
    declare -A cols

    common::get_keys_matrix get_variable_options rows cols
    for var in "${!rows[@]}"; do
        if [[ "$param" == "${get_variable_options[$var,arg]}" ]] \
            || [[ "$param" == "${get_variable_options[$var,short]:-}" ]]; then 
            res="$var"
        fi
    done
    echo "$res"
)

common::get_array_from_str() {
    local -n _get_array_from_str_arr="$1"
    local _get_array_from_str_var="$2"

    declare -a "_get_array_from_str_tmp=( $(echo "$_get_array_from_str_var" | sed -e 's#(#\\(#g' -e 's#)#\\)#g') )"
    _get_array_from_str_arr=("${_get_array_from_str_tmp[@]}")
}
