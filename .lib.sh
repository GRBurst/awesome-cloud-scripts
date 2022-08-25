#! /usr/bin/env bash

declare -A _lib_params_assoc
declare -a _lib_params_order

_print_error() (
    local _print_error_msg="$1"
    echo -e "\e[31m[ERROR] ${_print_error_msg}\e[0m"
)

_check_param() (
    local -n _check_param_args="$1"
    local -n _check_param_lookup="$2"

    if [[ " ${_check_param_args[*]} " =~ " ${_check_param_lookup[short]} " ]] || [[ " ${_check_param_args[*]} " =~ " ${_check_param_lookup[arg]} " ]]; then
        return 0
    fi

    return 1
)

_check_param_with_env() (
    local -n _with_env_check_args="$1"
    local -n _with_env_check_lookup="$2"

    if [[ ! -z "${_with_env_check_lookup[value]:+unset}" ]] && [[ -n "${_with_env_check_lookup[value]}" ]]; then
        return 0
    fi

    if ( _check_param _with_env_check_args _with_env_check_lookup ); then
        return 0
    else
        if [[ -z "${_with_env_check_lookup[value]:+unset}" ]]; then
            _print_error "${_with_env_check_lookup[name]} parameter required but not provided."
        else
            _print_error "${_with_env_check_lookup[name]} environment variable or parameter required but not provided."
        fi
    fi
    return 1
)

_check_row() (
    local -n _check_row_args="$1"
    local -n _check_row_lookup="$2"

    if [[ "${_check_row_lookup[required]}" == "true" ]]; then
        _check_param_with_env _check_row_args _check_row_lookup || return 1
    fi
)

_get_keys_matrix() {
    local -n _get_keys_matrix_assoc="$1"
    local -n _get_keys_matrix_rows="$2"
    local -n _get_keys_matrix_cols="$3"
    for var in "${!_get_keys_matrix_assoc[@]}"; do
        IFS=',' read -ra _key_arr <<< "${var}"
        _get_keys_matrix_rows["${_key_arr[0]}"]=1
        _get_keys_matrix_cols["${_key_arr[1]}"]=1
    done
}

check_requirements() (
    local -n _requirements_args="$1"
    local -n _requirements_lookup="$2"

    unset test_assoc_array
    if (( ${BASH_VERSINFO:-0} < 4 )) || (! declare -A test_assoc_array); then
        _print_error "associative arrays not supported!"
        exit 1
    fi

    declare -A _check_requirements_rows
    declare -A _check_requirements_cols
    _get_keys_matrix _requirements_lookup _check_requirements_rows _check_requirements_cols

    for var in "${!_check_requirements_rows[@]}"; do
        declare -A _row
        for attr in "${!_check_requirements_cols[@]}"; do
            if [[ ! -z "${_requirements_lookup[$var,$attr]:+unset}" ]]; then
                _row+=(["$attr"]="${_requirements_lookup[$var,$attr]}")
            fi
        done

        _check_row _requirements_args _row || return 1
        unset _row
    done

    return 0
)


_assign() {
    local -n assign_args="$1"

    if [[ -n "${3:-}" ]]; then
        assign_args["$2,value"]="$3"
        return 0
    else
        _print_error "Missing value for ${assign_args[$2,name]}"
        return 1
    fi
}

get_args() {
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

configure() {
    local -n _configure_args="$1"
    local -n _configure_options="$2"

    if (( ${#_configure_args[@]} == 0 )) || (( ${#_configure_options[@]} == 0)); then
        return 0
    fi

    declare -A _configure_options_rows
    declare -A _configure_options_cols
    _get_keys_matrix _configure_options _configure_options_rows _configure_options_cols

    for var in "${!_configure_options_rows[@]}"; do
        for i in "${!_configure_args[@]}"; do
            if [[ "${_configure_args[$i]}" == "${_configure_options[$var,arg]}" ]] || [[ "${_configure_args[$i]}" == "${_configure_options[$var,short]}" ]]; then
                if [[ "${_configure_options[$var,tpe]:-}" != "bool" ]]; then
                    _assign _configure_options "$var" "${_configure_args[$((i+1))]:-}"
                else
                    _assign _configure_options "$var" "true"
                fi
            fi
        done
    done
}

translate_args() {
    local -n _translate_args="$1"

    if [[ -n "${1:+unset}" ]]; then
        local -A _translate_rows

        for key in "${!_translate_args[@]}"; do
            IFS=',' read -ra _key_arr <<< "${key}"
            _translate_rows["${_key_arr[0]}"]=1
        done

        for var in "${!_translate_rows[@]}"; do
            if [[ -n "${_translate_args[$var,value]:+unset}" ]]; then
                # value is set and not empty
                local _translate_args_param_arg_key="$var,arg"
                local _translate_args_param_val_key="$var,value"
                _lib_params_assoc+=( ["$_translate_args_param_arg_key"]="${_translate_args[$_translate_args_param_arg_key]}" )
                _lib_params_order+=( "$_translate_args_param_arg_key" )
                if [[ "${_translate_args[$var,tpe]:-}" != "bool" ]]; then
                    _lib_params_assoc+=( ["$_translate_args_param_val_key"]="${_translate_args[$_translate_args_param_val_key]}" )
                    _lib_params_order+=( "$_translate_args_param_val_key" )
                fi
            fi
        done
    fi
}


process_args() {
    local -n _process_args_args="$1"
    local -n _process_args_options="$2"
    local -n _process_args_params="$3"

    configure _process_args_args _process_args_options
    translate_args _process_args_options
    get_args _process_args_params
}
