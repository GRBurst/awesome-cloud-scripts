#! /usr/bin/env bash

unset test_assoc_array
if (( ${BASH_VERSINFO:-0} < 4 )) || (! declare -A test_assoc_array); then
    _print_error "associative arrays not supported!"
    exit 1
fi

declare -A _lib_params_assoc
declare -a _lib_params_order

_print_error() (
    local _print_error_msg="$@"
    echo -e "\e[31m[ERROR] ${_print_error_msg}\e[0m"
    # exit 1
)
_print_debug() (
    if [[ "${DEBUG:-}" == "true" ]]; then
        local _print_debug_msg="$@"
        echo -e "\e[36m[DEBUG] ${_print_debug_msg}\e[0m"
    fi
)
_print_debug_success() (
    if [[ "${DEBUG:-}" == "true" ]]; then
        local _print_debug_msg="$@"
        echo -e "\e[32m[DEBUG] ${_print_debug_msg}\e[0m"
    fi
)

_print_var_usage() (
    printf '\n  %s | %s \t# %s %s' "$1" "$2" "$3" "$4"
)

_generate_usage() (
    local -n _generate_usage_options="$1"

    local -A _generate_usage_rows
    local -A _generate_usage_cols
    _get_keys_matrix _generate_usage_options _generate_usage_rows _generate_usage_cols

    local _generate_usage_required
    local _generate_usage_optional
    local _generate_usage_required_env
    local _generate_usage_optional_env

    for var in "${!_generate_usage_rows[@]}"; do
        if [[ -n "${_generate_usage_options[$var,value]+unset}" ]]; then
            if [[ "${_generate_usage_options[$var,required]}" == "true" ]]; then
                _generate_usage_required_env+="$(_print_var_usage "${_generate_usage_options[$var,short]}" "${_generate_usage_options[$var,arg]}" "${_generate_usage_options[$var,name]}" "variable or argument")"
            else
                _generate_usage_optional_env+="$(_print_var_usage "${_generate_usage_options[$var,short]}" "${_generate_usage_options[$var,arg]}" "${_generate_usage_options[$var,name]}" "variable or argument")"
            fi
        else
            if [[ "${_generate_usage_options[$var,required]}" == "true" ]]; then
                _generate_usage_required+="$(_print_var_usage "${_generate_usage_options[$var,short]}" "${_generate_usage_options[$var,arg]}" "${_generate_usage_options[$var,name]}" "argument")"
            else
                _generate_usage_optional+="$(_print_var_usage "${_generate_usage_options[$var,short]}" "${_generate_usage_options[$var,arg]}" "${_generate_usage_options[$var,name]}" "argument")"
            fi
        fi
    done

    cat <<-USAGE
Arguments and Environment
---------

Required environment: ${_generate_usage_required_env}

Optional environment: ${_generate_usage_optional_env}

Required arguments: ${_generate_usage_required}

Optional arguments: ${_generate_usage_optional}

USAGE
)

_get_keys_matrix() {
    local -n _get_keys_matrix_assoc="$1"
    local -n _get_keys_matrix_rows="$2"
    local -n _get_keys_matrix_cols="$3"
    # We create two arrays for the rows and column keys that doesn't contain duplicates
    for var in "${!_get_keys_matrix_assoc[@]}"; do
        IFS=',' read -ra _key_arr <<< "${var}"
        _get_keys_matrix_rows["${_key_arr[0]}"]=1
        _get_keys_matrix_cols["${_key_arr[1]}"]=1
    done
}

_check_param() (
    local -n _check_param_options="$1"
    local -n _check_param_args="$2"
    local _check_param_var="$3"

    _print_debug "check if ${_check_param_options["$_check_param_var",short]} or ${_check_param_options["$_check_param_var",arg]} are contained in: ${_check_param_args[*]}"

    if [[ " ${_check_param_args[*]} " =~ " ${_check_param_options["$_check_param_var",short]} " ]] || [[ " ${_check_param_args[*]} " =~ " ${_check_param_options["$_check_param_var",arg]} " ]]; then
        return 0
    fi

    return 1
)

_check_param_with_env() (
    local -n _check_param_with_env_options="$1"
    local -n _check_param_with_env_args="$2"
    local _check_param_with_env_var="$3"

    _print_debug "${_check_param_with_env_options["$_check_param_with_env_var",name]} is required, checking if provided."

    if [[ ! -z "${_check_param_with_env_options["$_check_param_with_env_var",value]:+unset}" ]] && [[ -n "${_check_param_with_env_options["$_check_param_with_env_var",value]}" ]]; then
        # value is required and provided as environment variable
        _print_debug "${_check_param_with_env_options["$_check_param_with_env_var",name]} provided via environment variable."
        return 0
    fi

    if ( _check_param _check_param_with_env_options  _check_param_with_env_args "$_check_param_with_env_var" ); then
        # parameter is provided
        _print_debug "$_check_param_with_env_var provided via parameter."
        return 0
    else
        if [[ -z "${_check_param_with_env_options["$_check_param_with_env_var",value]:+unset}" ]]; then
            # value can only be provided as parameter (value not defined), but the parameter is not provided
            _print_error "${_check_param_with_env_options["$_check_param_with_env_var",name]} parameter required but not provided."
        else
            # value can be provided as environment variable or parameter (value is defined but empty), but the parameter is not provided in either way
            _print_error "${_check_param_with_env_options["$_check_param_with_env_var",name]} environment variable or parameter required but not provided."
        fi
    fi
    return 1
)

check_requirements() {
    local -n _check_requirements_options="$1"
    local -n _check_requirements_args="$2"

    _print_debug "checking requirements"

    declare -A _check_requirements_rows
    declare -A _check_requirements_cols
    _get_keys_matrix _check_requirements_options _check_requirements_rows _check_requirements_cols

    # Iterate all variables (rows of the option matrix) and check if the required parameters are set
    # No sanity or value check here, we only check if all parameters are provided
    for var in "${!_check_requirements_rows[@]}"; do
        if [[ "${_check_requirements_options[$var,required]:-}" != "true" ]]; then 
            _print_debug "${_check_requirements_options[$var,name]:-} not required, skipping"
            continue
            fi
        _check_param_with_env _check_requirements_options _check_requirements_args "$var" || return 1
        done

    _print_debug_success "All required parameters are provided. Continuing with sanity check."

    local i=0
    while (( i < ${#_check_requirements_args[@]} )); do # args provided by user
        # We check all vars wether they are required and check them
        for var in "${!_check_requirements_rows[@]}"; do # all variables from options
            if [[ "${_check_requirements_options[$var,required]}" == "true" ]] || ((0 < 1)); then 

                # Found arg in options
                if [[ "${_check_requirements_args[$i]}" == "${_check_requirements_options[$var,arg]}" ]] || [[ "${_check_requirements_args[$i]}" == "${_check_requirements_options[$var,short]}" ]]; then

                    local j=1
                    while (( j <= ${_check_requirements_options[$var,pos]:-1} )) \
                        && ( [[ -n "${_check_requirements_options[$var,tpe]:+unset}" ]] \
                            && [[ "${_check_requirements_options[$var,tpe]}" != "bool" ]] \
                            || [[ -z "${_check_requirements_options[$var,tpe]:+unset}" ]]); do # args provided by user

                        if ! (for var in "${!_check_requirements_rows[@]}"; do # all variables from options

                            # if [[ " ${_check_param_args[*]} " =~ " ${_check_requirements_options[$var,arg]} " ]] || [[ " ${_check_param_args[*]} " =~ " ${_check_requirements_options[$var,short]} " ]]; then

                            if [[ "${_check_requirements_args[$((i+j))]:+unset}" ]] \
                                && ([[ "${_check_requirements_args[$((i+j))]}" == "${_check_requirements_options[$var,arg]}" ]] \
                                || [[ "${_check_requirements_args[$((i+j))]}" == "${_check_requirements_options[$var,short]}" ]]); then
                                return 1
                            fi
                        done); then
                            _print_error "Aborting ${_check_requirements_args[$i]} = ${_check_requirements_args[$((i+j))]}"
                            exit 1
                        fi
                        let j++
                    done
                fi
            fi
        done
        let i++
    done

    return 0
)


_assign() {
    local -n _assign_args="$1"

    if [[ -n "${3:-}" ]]; then
        _assign_args["$2,value"]="$3"
        return 0
    else
        _print_error "Missing value for ${_assign_args[$2,name]}"
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

    # Go through all parameter option
    for var in "${!_configure_options_rows[@]}"; do
        for i in "${!_configure_args[@]}"; do
            # Compare if short or long parameter is provided
            if [[ "${_configure_args[$i]}" == "${_configure_options[$var,arg]}" ]] || [[ "${_configure_args[$i]}" == "${_configure_options[$var,short]}" ]]; then
                # If not of type boolean / switch, we read the next argument (which should be the value)
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
