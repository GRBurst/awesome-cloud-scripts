#! /usr/bin/env bash

_check_param() (
    local -n _check_param_args=$1
    local -n _check_param_lookup=$2

    if [[ " ${_check_param_args[*]} " =~ " ${_check_param_lookup[short]} " ]] || [[ " ${_check_param_args[*]} " =~ " ${_check_param_lookup[arg]} " ]]; then
        return 0
    fi

    return 1
)

_check_param_with_env() (
    local -n _with_env_check_args=$1
    local -n _with_env_check_lookup=$2

    if [[ ! -z "${_with_env_check_lookup[value]+unset}" ]] && [[ -n "${_with_env_check_lookup[value]}" ]]; then
        return 0
    fi

    if ( _check_param _with_env_check_args _with_env_check_lookup ); then
        return 0
    else
        if [[ -z "${_with_env_check_lookup[value]+unset}" ]]; then
            echo "${_with_env_check_lookup[name]} parameter required but not provided."
        else
            echo "${_with_env_check_lookup[name]} environment variable or parameter required but not provided."
        fi
    fi
    return 1
)

_check_row() (
    local -n _check_row_args=$1
    local -n _check_row_lookup=$2

    if [[ "${_check_row_lookup[required]}" == "true" ]]; then
        _check_param_with_env _check_row_args _check_row_lookup || return 1
    fi
)

check_requirements() (
    local -n _requirements_args=$1
    local -n _requirements_lookup=$2

    unset test_assoc_array
    if (( ${BASH_VERSINFO:-0} < 4 )) || (! declare -A test_assoc_array); then
        echo "associative arrays not supported!"
        exit 1
    fi

    declare -A _check_requirements_rows
    declare -A _check_requirements_cols

    for var in "${!_requirements_lookup[@]}"; do
        IFS=','
        read -ra _key_arr <<< "${var}"
        _check_requirements_rows[${_key_arr[0]}]=1
        _check_requirements_cols[${_key_arr[1]}]=1
    done

    for var in "${!_check_requirements_rows[@]}"; do
        declare -A _row
        for attr in "${!_check_requirements_cols[@]}"; do
            if [[ ! -z "${_requirements_lookup[$var,$attr]+unset}" ]]; then
                _row+=([$attr]="${_requirements_lookup[$var,$attr]}")
            fi
        done

        _check_row _requirements_args _row || return 1
        unset _row
    done

    return 0
)

translate_args() (
    local -n _translate_args=$1

    local -A _translate_rows
    local param_string=""

    for var in "${!_translate_args[@]}"; do
        IFS=','
        read -ra _key_arr <<< "${var}"
        _translate_rows[${_key_arr[0]}]=1
    done

    for var in "${!_translate_rows[@]}"; do
    if [[ -n ${_translate_args[$var,value]:-} ]]; then
        param_string+="${_translate_args[$var,arg]} ${_translate_args[$var,value]} "
    fi
    done

    echo "$param_string"
)

assign() {
    local -n assign_args=$1

    if [[ -n ${3:-} ]]; then
        assign_args[$2,value]="$3"
        return 0
    else
        echo "Missing value for ${assign_args[$2,name]}"
        return 1
    fi
}
