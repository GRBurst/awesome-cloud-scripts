#! /usr/bin/env bash
set -Eeuo pipefail

declare -xr SCRIPT_COOK_IO_LOADED=true

if [[ "${SCRIPT_COOK_COMMON_LOADED:-}" != "true" ]]; then
    source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
fi

io::print_error() (
    local msg
    msg="$*"
    >&2 echo -e "\e[31m[ERROR] ${msg}\e[0m"
)

io::print_debug() (
    if [[ "${DEBUG:-}" == "true" ]]; then
        local msg
        msg="$*"
        >&2 echo -e "\e[36m[DEBUG] ${msg}\e[0m"
    fi
)

io::print_debug_error() (
    if [[ "${DEBUG:-}" == "true" ]]; then
        io::print_error "$*"
    fi
)

io::print_debug_success() (
    if [[ "${DEBUG:-}" == "true" ]]; then
        local msg
        msg="$*"
        >&2 echo -e "\e[32m[DEBUG] ${msg}\e[0m"
    fi
)

io::print_var_usage() (
    printf "\n  %-${5}s | %-${6}s \t# %s %s" "$1" "$2" "$3" "$4"
)

io::print_section_usage() (
    if [[ -n "${2:-}" ]]; then 
        printf '\n\n%s:%s\n' "$1" "$2"
    else
        echo ""
    fi
)

io::generate_usage() (
    local -rn genenrate_usage_options_ref="$1"
    local -A rows cols

    common::get_keys_matrix genenrate_usage_options_ref rows cols

    local required optional required_env optional_env
    local -i arg_length=0 short_length=0

    for var in "${!rows[@]}"; do
        local short="${genenrate_usage_options_ref[$var,short]:-}"
        local arg="${genenrate_usage_options_ref[$var,arg]:-}"
        if (( ${#short} > short_length )); then
            (( short_length=${#short} ))
        fi
        if (( ${#arg} > arg_length )); then
            (( arg_length=${#arg} ))
        fi
    done

    for var in "${!rows[@]}"; do
        if [[ -n "${genenrate_usage_options_ref[$var,value]+set}" ]]; then
            if [[ "${genenrate_usage_options_ref[$var,required]}" == "true" ]]; then
                required_env+="$(\
                    io::print_var_usage \
                    "${genenrate_usage_options_ref[$var,short]:-}" \
                    "${genenrate_usage_options_ref[$var,arg]}" \
                    "${genenrate_usage_options_ref[$var,desc]}" \
                    "variable or argument" \
                    $short_length $arg_length)"
            else
                optional_env+="$(\
                    io::print_var_usage \
                    "${genenrate_usage_options_ref[$var,short]:-}" \
                    "${genenrate_usage_options_ref[$var,arg]}" \
                    "${genenrate_usage_options_ref[$var,desc]}" \
                    "variable or argument" \
                    $short_length $arg_length)"
            fi
        else
            if [[ "${genenrate_usage_options_ref[$var,required]}" == "true" ]]; then
                required+="$(\
                    io::print_var_usage \
                    "${genenrate_usage_options_ref[$var,short]:-}" \
                    "${genenrate_usage_options_ref[$var,arg]}" \
                    "${genenrate_usage_options_ref[$var,desc]}" \
                    "argument" \
                    $short_length $arg_length)"
            else
                optional+="$(\
                    io::print_var_usage \
                    "${genenrate_usage_options_ref[$var,short]:-}" \
                    "${genenrate_usage_options_ref[$var,arg]}" \
                    "${genenrate_usage_options_ref[$var,desc]}" \
                    "argument" \
                    $short_length $arg_length)"
            fi
        fi
    done

    local usage_string
    usage_string="$(cat <<-USAGE
Arguments and Environment
---------

USAGE
)"

    usage_string+="$(io::print_section_usage "Required environment" "${required_env:-}" )"
    usage_string+="$(io::print_section_usage "Optional environment" "${optional_env:-}" )"
    usage_string+="$(io::print_section_usage "Required arguments"   "${required:-}"     )"
    usage_string+="$(io::print_section_usage "Optional arguments"   "${optional:-}"     )"

    echo "$usage_string"
)

io::print_option_matrix() (
    local -rn print_option_matrix_options_ref="$1"
    local -rn print_option_matrix_error_vars_ref="$2"

    local -A rows cols

    common::get_keys_matrix print_option_matrix_options_ref rows cols


    local -i var_length=0
    for var in "${!rows[@]}"; do
        if (( ${#var} > var_length )); then 
            var_length=${#var}
        fi
    done

    for var in "${!rows[@]}"; do
        for arg in "${!cols[@]}"; do
            local -i cell_length=0
            (( cell_length=${var_length}+${#arg}+3 ))
            if [[ -z "${print_option_matrix_options_ref[$var,$arg]+set}" ]]; then
                printf "%${cell_length}s" "   "
            elif [[ "${print_option_matrix_error_vars_ref[*]}" =~ "$var" ]]; then
                printf "\e[1m\e[31m%${cell_length}s\e[0m" "[$var,$arg]"
            else
                printf "%${cell_length}s" "[$var,$arg]"
            fi
            printf " | "
        done
        echo ""
    done

)

io::print_values_matrix() (
    local -rn print_values_matrix_options_ref="$1"

    local -A rows cols

    common::get_keys_matrix print_values_matrix_options_ref rows cols

    local -A cols_length
    for arg in "${!cols[@]}"; do
        for var in "${!rows[@]}"; do
            local val="${print_values_matrix_options_ref[$var,$arg]:-}"
            local -i length="${cols_length[$arg]:-0}"
            if (( "${#val}" > length )); then 
                cols_length+=( [$arg]=${#val} )
            fi
        done
    done

    local -i total_length=0
    for arg in "${!cols[@]}"; do
        if (( "${#arg}" > "${cols_length[$arg]}" )); then 
            cols_length+=( [$arg]=${#arg} )
        fi
        printf "%${cols_length[$arg]}s" "$arg"
        printf " | "
        (( total_length+=${cols_length[$arg]}+3 ))
    done

    printf "\n"
    printf '%0.s-' $(seq 2 $total_length)
    printf "\n"

    for var in "${!rows[@]}"; do
        for arg in "${!cols[@]}"; do
            if [[ -z "${print_values_matrix_options_ref[$var,$arg]+set}" ]]; then
                printf "%${cols_length[$arg]}s" " "
            else
                printf "%${cols_length[$arg]}s" "${print_values_matrix_options_ref[$var,$arg]:-}"
            fi
            printf " | "
        done
        printf "\n"
    done

)
