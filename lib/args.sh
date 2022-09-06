#! /usr/bin/env bash
set -Eeuo pipefail

declare -rx SCRIPT_COOK_ARGS_LOADED="true"

if [[ "${SCRIPT_COOK_COMMON_LOADED:-}" != "true" ]]; then
    source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
fi
if [[ "${SCRIPT_COOK_IO_LOADED:-}" != "true" ]]; then
    source "$(dirname "${BASH_SOURCE[0]}")/io.sh"
fi

declare -rA args_defaults=( [required]=false [arity]=1 [tpe]="named" )
declare -A _lib_params_assoc
declare -a _lib_params_order

args::assign() {
    local -n _assign_args="$1"

    if [[ -n "${3:-}" ]]; then
        if [[ -n "${_assign_args["$2",value]:+set}" ]] && (( "${_assign_args["$2",arity]:-1}" > 1)); then
            _assign_args+=( ["$2,value"]+=" $3" )
        else
            _assign_args["$2,value"]="$3"
        fi
        return 0
    else
        io::print_error "Missing value for ${_assign_args[$2,desc]}"
        return 1
    fi
}

args::fill_default() {
    local -n fill_default_options_ref="$1"
    local var="$2"
    local par="$3"
    for arg in required arity tpe; do
        if [[ -z "${fill_default_options_ref[$var,$arg]:+set}" ]]; then
            fill_default_options_ref+=( [$var,$arg]="${args_defaults[$arg]}" )
        fi
    done
    if [[ -z "${fill_default_options_ref[$var,desc]:+set}" ]]; then
        fill_default_options_ref+=( [$var,desc]="${fill_default_options_ref[$var,arg]:-$par}" )
    fi

}

args::configure() {
    local -n _configure_options="$1"
    local -n _configure_args="$2"

    if (( ${#_configure_args[@]} == 0 )) || (( ${#_configure_options[@]} == 0)); then
        return 0
    fi

    declare -A _configure_options_rows
    declare -A _configure_options_cols
    common::get_keys_matrix _configure_options _configure_options_rows _configure_options_cols

    local total_args_length="${#_configure_args[@]}"
    local -i i=0
    while (( i < total_args_length )); do # Iterate all user provided args
        local user_argument="${_configure_args[$i]}"
        io::print_debug "configure user_argument[$i] = $user_argument"

        # Get current variable for parameter
        local var
        var="$(common::get_variable_from_param _configure_options "$user_argument")"

        args::fill_default _configure_options "$var" "$user_argument"

        if [[ "${_configure_options[$var,tpe]:-}" == "flag" ]]; then
                args::assign _configure_options "$var" "true" || return 1
                ((i++))
        else
            local user_arg_arity=${_configure_options[$var,arity]:-1}
            local -i j=1
            while ((j <= user_arg_arity)); do
                io::print_debug "args::assign _configure_options $var ${_configure_args[$((i+j))]:-}"
                args::assign _configure_options "$var" "${_configure_args[$((i+j))]:-}" || return 1
                ((j++))
            done
            (( i=i+user_arg_arity+1 ))
        fi
    done
    return 0
}

args::translate() {
    local -n _translate_args="$1"

    if [[ -n "${1:+set}" ]]; then
        local -A _translate_rows

        for key in "${!_translate_args[@]}"; do
            IFS=',' read -ra _key_arr <<< "${key}"
            _translate_rows["${_key_arr[0]}"]=1
        done

        for var in "${!_translate_rows[@]}"; do
            if [[ -n "${_translate_args[$var,value]:+set}" ]]; then
                # value is set and not empty
                local _translate_args_param_arg_key="$var,arg"
                local _translate_args_param_val_key="$var,value"
                _lib_params_assoc+=( ["$_translate_args_param_arg_key"]="${_translate_args[$_translate_args_param_arg_key]}" )
                _lib_params_order+=( "$_translate_args_param_arg_key" )
                if [[ "${_translate_args[$var,tpe]:-}" != "flag" ]]; then
                    _lib_params_assoc+=( ["$_translate_args_param_val_key"]="${_translate_args[$_translate_args_param_val_key]}" )
                    _lib_params_order+=( "$_translate_args_param_val_key" )
                fi
            fi
        done
    fi
}

args::get() {
    local -n _get_args_res="$1"
    local _get_args_var="${2:-}"

    if [[ -z "$_get_args_var" ]]; then
        for key in "${_lib_params_order[@]}"; do
            _get_args_res+=( "${_lib_params_assoc[$key]}" )
        done
    else
        for key in "${_lib_params_order[@]}"; do
            IFS=',' read -ra _key_arr <<< "${key}"
            if [[ "${_key_arr[0]}" == "$_get_args_var" ]]; then
                _get_args_res+=( "${_lib_params_assoc[$key]}" )
            fi
        done
    fi
}

args::get_str() {
    local -a _get_args_str_res
    local _get_args_str="${1:-}"

    args::get _get_args_str_res "$_get_args_str"
    echo "${_get_args_str_res[@]}"
}

args::get_values() {
    local -a _get_values_args_res
    local -n _get_values_res="$1"
    local _get_values_var="${2:-}"

    args::get _get_values_args_res "$_get_values_var"

    readarray -t _get_values_res <<< "${_get_values_args_res[@]:1}"
}

args::get_values_str() {
    local -a _get_values_str_res
    local _get_values_str="${1:-}"

    args::get_values _get_values_str_res "$_get_values_str"
    echo "${_get_values_str_res[@]}"
}

args::process() {
    local -n process_options="$1"
    local -n process_args="$2"
    local -n process_params="$3"

    args::configure process_options process_args || io::print_debug "configure terminated with $?" && return 1
    args::translate process_options              || io::print_debug "translate terminated with $?" && return 1
    args::get       process_params               || io::print_debug "get_args terminated with $?"  && return 1
}
