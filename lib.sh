#! /usr/bin/env bash

unset test_assoc_array
if (( ${BASH_VERSINFO:-0} < 4 )) || (! declare -A test_assoc_array); then
    _print_error "associative arrays not supported!"
    exit 1
fi

cleanup() ( >&2 echo "Error: (${1:-}) occurred on line ${2:-} in ${3:-}" )
trap 'cleanup $? $LINENO ${BASH_SOURCE##*/}' ERR

declare -A _lib_params_assoc
declare -a _lib_params_order

_print_error() (
    local _print_error_msg="$*"
    echo -e "\e[31m[ERROR] ${_print_error_msg}\e[0m"
)
_print_debug() (
    if [[ "${DEBUG:-}" == "true" ]]; then
        local _print_debug_msg="$*"
        >&2 echo -e "\e[36m[DEBUG] ${_print_debug_msg}\e[0m"
    fi
)
_print_debug_success() (
    if [[ "${DEBUG:-}" == "true" ]]; then
        local _print_debug_msg="$*"
        >&2 echo -e "\e[32m[DEBUG] ${_print_debug_msg}\e[0m"
    fi
)

_print_var_usage() (
    printf '\n%4s | %-30s # %s %s' "$1" "$2" "$3" "$4"
)
_print_section_usage() (
    if [[ -n "${2:-}" ]]; then 
        printf '\n\n%s:%s\n' "$1" "$2"
    else
        echo ""
    fi
)

_get_keys_matrix() {
    local -n _get_keys_matrix_assoc="$1"
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
                _generate_usage_required_env+="$(_print_var_usage "${_generate_usage_options[$var,short]:-}" "${_generate_usage_options[$var,arg]}" "${_generate_usage_options[$var,name]}" "variable or argument")"
            else
                _generate_usage_optional_env+="$(_print_var_usage "${_generate_usage_options[$var,short]:-}" "${_generate_usage_options[$var,arg]}" "${_generate_usage_options[$var,name]}" "variable or argument")"
            fi
        else
            if [[ "${_generate_usage_options[$var,required]}" == "true" ]]; then
                _generate_usage_required+="$(_print_var_usage "${_generate_usage_options[$var,short]:-}" "${_generate_usage_options[$var,arg]}" "${_generate_usage_options[$var,name]}" "argument")"
            else
                _generate_usage_optional+="$(_print_var_usage "${_generate_usage_options[$var,short]:-}" "${_generate_usage_options[$var,arg]}" "${_generate_usage_options[$var,name]}" "argument")"
            fi
        fi
    done

    local usage_string
    usage_string="$(cat <<-USAGE
Arguments and Environment
---------

USAGE
)"

    usage_string+="$(_print_section_usage "Required environment" "${_generate_usage_required_env:-}" )"
    usage_string+="$(_print_section_usage "Optional environment" "${_generate_usage_optional_env:-}" )"
    usage_string+="$(_print_section_usage "Required arguments"   "${_generate_usage_required:-}"     )"
    usage_string+="$(_print_section_usage "Optional arguments"   "${_generate_usage_optional:-}"     )"

    echo "$usage_string"
)

_print_option_matrix() (
    local -n _print_option_matrix_options="$1"
    local -n _print_option_matrix_err_vars="$2"

    local -A _print_option_matrix_rows
    local -A _print_option_matrix_cols

    _get_keys_matrix _print_option_matrix_options _print_option_matrix_rows _print_option_matrix_cols


    # local _red_color="$(tput setaf 1)"
    # local _normal_color="$(tput sgr0)"
    # echo -e "\e[31m[ERROR] ${_print_error_msg}\e[0m"
    local _var_length=0
    for var in "${!_print_option_matrix_rows[@]}"; do
        if (( ${#var} > _var_length )); then 
            _var_length=${#var}
        fi
    done
    for var in "${!_print_option_matrix_rows[@]}"; do
        for arg in "${!_print_option_matrix_cols[@]}"; do
            local _cell_length=0
            (( _cell_length=${_var_length}+${#arg}+3 ))
            if [[ -z "${_print_option_matrix_options[$var,$arg]+unset}" ]]; then
                printf "%${_cell_length}s" "   "
            elif [[ "${_print_option_matrix_err_vars[*]}" =~ "$var" ]]; then
                # printf '%14s | ' "${_red_color}[$var,$arg]${_normal_color}"
                printf "\e[1m\e[31m%${_cell_length}s\e[0m" "[$var,$arg]"
            else
                printf "%${_cell_length}s" "[$var,$arg]"
            fi
            printf " | "
        done
        echo ""
    done

)

_check_options() (
    local -n _check_options_options="$1"
    local -a _check_options_error_vars
    local -A _check_options_rows
    local -A _check_options_cols

    _get_keys_matrix _check_options_options _check_options_rows _check_options_cols

    for var in "${!_check_options_rows[@]}"; do
        if [[ -z "${_check_options_options[$var,arg]:+unset}" ]]; then
            _print_error "[$var,arg] missing. Please provide a (long) argument by adding [$var,arg] to your options."
            _check_options_error_vars+=( "$var" )
        fi

        if [[ -z "${_check_options_options[$var,required]:+unset}" ]]; then
            _print_error "[$var,required] missing. Please define the required argument by adding [$var,required] to your options."
            _check_options_error_vars+=( "$var" )
        fi
    done
    if [[ -n "${_check_options_error_vars:+unset}" ]]; then
        _print_error "Found ${#_check_options_error_vars} errors"
        _print_option_matrix _check_options_options _check_options_error_vars
        exit 1
    fi
)

_check_param() (
    local -n _check_param_options="$1"
    local -n _check_param_args="$2"
    local _check_param_var="$3"

    _print_debug "check if any of (\
${_check_param_options["$_check_param_var",short]:+" ${_check_param_options["$_check_param_var",short]}, "}\
${_check_param_options["$_check_param_var",arg]}\
) are contained in: ${_check_param_args[*]})"

    if [[ "${_check_param_args[*]}" =~ ${_check_param_options["$_check_param_var",short]:-} ]] \
        || [[ "${_check_param_args[*]}" =~ ${_check_param_options["$_check_param_var",arg]} ]]
    then
        return 0
    fi

    return 1
)

_check_param_with_env() (
    local -n _check_param_with_env_options="$1"
    local -n _check_param_with_env_args="$2"
    local _check_param_with_env_var="$3"

    _print_debug "${_check_param_with_env_options["$_check_param_with_env_var",name]} is required, checking if provided."

    if [[ -n "${_check_param_with_env_options["$_check_param_with_env_var",value]:+unset}" ]] && [[ -n "${_check_param_with_env_options["$_check_param_with_env_var",value]}" ]]; then
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

_assign() {
    local -n _assign_args="$1"

    if [[ -n "${3:-}" ]]; then
        if [[ -n "${_assign_args["$2",value]:+unset}" ]] && (( "${_assign_args["$2",pos]:-1}" > 1)); then
            _assign_args+=( ["$2,value"]+=" $3" )
        else
            _assign_args["$2,value"]="$3"
        fi
        return 0
    else
        _print_error "Missing value for ${_assign_args[$2,name]}"
        return 1
    fi
}

_get_variable_from_param() (
    local -n _get_variable_from_param_options="$1"
    local _get_variable_from_param_param="$2"
    local res=""

    declare -A _get_variable_from_param_rows
    declare -A _get_variable_from_param_cols

    _get_keys_matrix _get_variable_from_param_options _get_variable_from_param_rows _get_variable_from_param_cols
    for var in "${!_get_variable_from_param_rows[@]}"; do
        if [[ "$_get_variable_from_param_param" == "${_get_variable_from_param_options[$var,arg]}" ]] \
            || [[ "$_get_variable_from_param_param" == "${_get_variable_from_param_options[$var,short]:-}" ]]; then 
            res="$var"
        fi
    done
    echo "$res"
)

check_requirements() {
    local -n _check_requirements_options="$1"
    local -n _check_requirements_args="$2"

    _check_options _check_requirements_options || return 1

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

    # Iterate all user provided arguments one by one and search for the corresponding option.
    # While checking, we test if:
    # 1. A required parameter is present
    # 2. The parameter is followed by n values
    #   2.1 Values are arguments that are no parameter for the script itself
    #   2.2 If there is a value that equals a parameter, we have to check
    #       2.2.1 whether the parameter is already given or
    #       2.2.2 the parameter is present in a later part of the parameter array
    #   2.3 If the parameter is of type boolean, we don't have to check for further value arguments.
    # 3. If the parameter is not required, we still have to check its sanity by precessing all steps from 2.

    local total_args_length="${#_check_requirements_args[@]}"
    _print_debug "Total of $total_args_length arguments"
    local i=0
    while (( i < total_args_length )); do # Iterate all user provided args
        local user_argument="${_check_requirements_args[$i]}"
        _print_debug "checking user_argument[$i] = $user_argument"

        # Get current variable name for parameter
        local var
        var="$(_get_variable_from_param _check_requirements_options "$user_argument")"

        # Current argument is not found in options, continue search for parameters
        if [[ -z "$var" ]]; then
            _print_debug "  |$user_argument is not a recognized option, continuing."
            ((i++))
            continue
        fi

        _print_debug "  |Starting options loop with var = $var, ${_check_requirements_options[$var,arg]:-}"

        # If the variable is has a type set and the type is boolean (tpe == bool),
        # we don't have to check the argument and continue
        if [[ -n "${_check_requirements_options[$var,tpe]:+unset}" ]] \
            && [[ "${_check_requirements_options[$var,tpe]:-}" == "bool" ]]; then
            _check_requirements_options+=( ["$var",_checked]="true" )
            _print_debug "  |$user_argument is boolean, skipping further checks"
            ((i++))
            continue
        fi

        # Now we check if the parameter got n arguments (pos), these are not a parameter itself,
        # unless the are provided again as a parameter after n arguments
        # Default number of positions is n=1.
        local user_arg_pos=${_check_requirements_options[$var,pos]:-1}

        # Separate check if the last argument is a parameter but no value is provided
        if (( i+user_arg_pos  >= total_args_length )); then
            _print_error "Aborting. Not enough values provided for last parameter ${_check_requirements_options[$var,name]}."
            return 1
        fi

        local j=$((i+1))
        # Search all following arguments for valid values
        while (( j <= i+user_arg_pos )); do
            if [[ -z "${_check_requirements_args[$j]:+unset}" ]]; then
                _print_error "Aborting. Not enough values provided for parameter ${_check_requirements_options[$var,name]}."
                return 1
            fi
            local next_user_argument="${_check_requirements_args[$j]}"
            _print_debug "    |next_user_argument[$j] = $next_user_argument"

            # Check if the next argument is not a parameter etc
            for next_var in "${!_check_requirements_rows[@]}"; do # all variables from options
                local next_argument_option="${_check_requirements_options[$next_var,arg]}"
                local next_argument_option_short="${_check_requirements_options[$next_var,short]:-}"

                # If the next argument does not equal a parameter, we are save to continue
                if [[ "$next_user_argument" != "$next_argument_option" ]] \
                    && [[ "$next_user_argument" != "$next_argument_option_short" ]]; then
                    _print_debug "      |$next_user_argument != parameter $next_argument_option and $next_argument_option_short, skipping further checks"
                    continue
                fi

                # If the argument equals a parameter, but that parameter is alreay checked correctly,
                # e.g. it was provided before and checked, we can continue
                if [[ "${_check_requirements_options[$next_var,_checked]:-}" == "true" ]]; then
                    _print_debug "      |[$j]$next_var is checked already, therefore this can be a valid value"
                    continue
                fi

                # Now, only if the parameter is provided again in the arguments, it can still be a valid
                # argument list and hence a valid command.
                local -i k=$((i+user_arg_pos+1))
                while (( k < total_args_length )); do # args provided by user
                    if [[ "$(_get_variable_from_param _check_requirements_options "$next_user_argument")" == "$(_get_variable_from_param _check_requirements_options "${_check_requirements_args[$k]}")" ]]; then
                        _print_debug "        |[$j]$next_user_argument is provided again later in the _check_requirements_args[$k]"
                        continue 2
                    fi
                    _print_debug "Lookahead argument is not the parameter $next_user_argument != ${_check_requirements_args[$k]}"
                    ((k++))
                done

                _print_error "Aborting. Value of $user_argument is $next_user_argument, which is a parameter, too. However, we couldn't find another $next_user_argument, so it seems like not enough argument are provided. The parameter $user_argument needs $user_arg_pos parameter(s)."
                return 1

            done

            ((j++))
            _print_debug "    |next value"

        done

        _print_debug_success "successfully checked $var($user_argument)"
        _check_requirements_options+=( ["$var",_checked]="true" )
        _print_debug "|next parameter"
        ((i=i+user_arg_pos+1))
    done

    return 0
}

configure() {
    local -n _configure_options="$1"
    local -n _configure_args="$2"

    if (( ${#_configure_args[@]} == 0 )) || (( ${#_configure_options[@]} == 0)); then
        return 0
    fi

    declare -A _configure_options_rows
    declare -A _configure_options_cols
    _get_keys_matrix _configure_options _configure_options_rows _configure_options_cols

    local total_args_length="${#_configure_args[@]}"
    local -i i=0
    while (( i < total_args_length )); do # Iterate all user provided args
        local user_argument="${_configure_args[$i]}"
        _print_debug "configure user_argument[$i] = $user_argument"

        # Get current variable name for parameter
        local var
        var="$(_get_variable_from_param _configure_options "$user_argument")"

        if [[ "${_configure_options[$var,tpe]:-}" == "bool" ]]; then
            _assign _configure_options "$var" "true"
            ((i++))
        else
            local user_arg_pos=${_configure_options[$var,pos]:-1}
            local -i j=1
            while ((j <= user_arg_pos)); do
                _print_debug "_assign _configure_options $var ${_configure_args[$((i+j))]:-}"
                _assign _configure_options "$var" "${_configure_args[$((i+j))]:-}"
                ((j++))
            done
            (( i=i+user_arg_pos+1 ))
        fi
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

get_args_str() {
    local -a _get_args_str_res
    local _get_args_str="${1:-}"

    get_args _get_args_str_res "$_get_args_str"
    echo "${_get_args_str_res[@]}"
}

get_values() {
    local -a _get_values_args_res
    local -n _get_values_res="$1"
    local _get_values_var="${2:-}"

    get_args _get_values_args_res "$_get_values_var"

    readarray -t _get_values_res <<< "${_get_values_args_res[@]:1}"
}

get_values_str() {
    local -a _get_values_str_res
    local _get_values_str="${1:-}"

    get_values _get_values_str_res "$_get_values_str"
    echo "${_get_values_str_res[@]}"
}

get_array_from_str() {
    local -n _get_array_from_str_arr="$1"
    local _get_array_from_str_var="$2"

    declare -a "_get_array_from_str_tmp=( $(echo "$_get_array_from_str_var" | sed -e 's#(#\\(#g' -e 's#)#\\)#g') )"
    _get_array_from_str_arr=("${_get_array_from_str_tmp[@]}")
}

process_args() {
    local -n _process_args_options="$1"
    local -n _process_args_args="$2"
    local -n _process_args_params="$3"

    configure _process_args_options _process_args_args || _print_debug "configure terminated with $?"
    translate_args _process_args_options || _print_debug "translate terminated with $?"
    get_args _process_args_params || _print_debug "get_args terminated with $?"
}
