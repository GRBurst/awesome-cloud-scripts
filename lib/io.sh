#! /usr/bin/env bash
set -Eeuo pipefail

declare -x SCRIPT_COOK_IO_LOADED=true

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
    local -rn genenrate_usage_inputs_ref="$1"
    local -r genenrate_usage_str="$2"
    local -A rows cols

    common::get_keys_matrix genenrate_usage_inputs_ref rows cols

    local required optional required_env optional_env
    local -i arg_length=0 short_length=0

    for var in "${!rows[@]}"; do
        local short="${genenrate_usage_inputs_ref[$var,short]:-}"
        local arg="${genenrate_usage_inputs_ref[$var,param]:-}"
        if (( ${#short} > short_length )); then
            (( short_length=${#short} ))
        fi
        if (( ${#arg} > arg_length )); then
            (( arg_length=${#arg} ))
        fi
    done

    for var in "${!rows[@]}"; do
        if [[ -n "${genenrate_usage_inputs_ref[$var,value]+set}" ]]; then
            if [[ "${genenrate_usage_inputs_ref[$var,required]:-false}" == "true" ]]; then
                required_env+="$(\
                    io::print_var_usage \
                    "${genenrate_usage_inputs_ref[$var,short]:-}" \
                    "${genenrate_usage_inputs_ref[$var,param]}" \
                    "${genenrate_usage_inputs_ref[$var,desc]}" \
                    "variable or argument" \
                    $short_length $arg_length)"
            else
                optional_env+="$(\
                    io::print_var_usage \
                    "${genenrate_usage_inputs_ref[$var,short]:-}" \
                    "${genenrate_usage_inputs_ref[$var,param]}" \
                    "${genenrate_usage_inputs_ref[$var,desc]}" \
                    "variable or argument" \
                    $short_length $arg_length)"
            fi
        else
            if [[ "${genenrate_usage_inputs_ref[$var,required]:-false}" == "true" ]]; then
                required+="$(\
                    io::print_var_usage \
                    "${genenrate_usage_inputs_ref[$var,short]:-}" \
                    "${genenrate_usage_inputs_ref[$var,param]}" \
                    "${genenrate_usage_inputs_ref[$var,desc]}" \
                    "argument" \
                    $short_length $arg_length)"
            else
                optional+="$(\
                    io::print_var_usage \
                    "${genenrate_usage_inputs_ref[$var,short]:-}" \
                    "${genenrate_usage_inputs_ref[$var,param]}" \
                    "${genenrate_usage_inputs_ref[$var,desc]}" \
                    "argument" \
                    $short_length $arg_length)"
            fi
        fi
    done

    local usage_string
    usage_string="$(cat <<-USAGE
$genenrate_usage_str


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

io::print_input_matrix() (
    local -rn print_input_matrix_inputs_ref="$1"
    local -rn print_input_matrix_error_vars_ref="$2"

    local -A rows cols

    common::get_keys_matrix print_input_matrix_inputs_ref rows cols


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
            if [[ -z "${print_input_matrix_inputs_ref[$var,$arg]+set}" ]]; then
                printf "%${cell_length}s" "   "
            elif [[ "${print_input_matrix_error_vars_ref[*]}" =~ "$var" ]]; then
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
    local -rn print_values_matrix_inputs_ref="$1"

    local -A rows cols

    common::get_keys_matrix print_values_matrix_inputs_ref rows cols

    local -A cols_length
    for arg in "${!cols[@]}"; do
        for var in "${!rows[@]}"; do
            local val="${print_values_matrix_inputs_ref[$var,$arg]:-}"
            local -i length="${cols_length[$arg]:-0}"
            if (( "${#val}" >= length )); then # >= to always set it
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
            if [[ -z "${print_values_matrix_inputs_ref[$var,$arg]+set}" ]]; then
                printf "%${cols_length[$arg]}s" " "
            else
                printf "%${cols_length[$arg]}s" "${print_values_matrix_inputs_ref[$var,$arg]:-}"
            fi
            printf " | "
        done
        printf "\n"
    done

)

io::parse() {
    local -n io_parse_inputs_ref="$1"
    local -r io_parse_inputs_str="$2"

    cleaned_inputs_str=$(echo "$io_parse_inputs_str" | grep -v "^#" | sed 's/ //g')
    delim="${cleaned_inputs_str:0:1}"
    prep_inputs="$(echo "${cleaned_inputs_str}" | sed -e 's/^|*//g' -e 's/|*$//g' -e 's/^[[:blank:]]*//g' -e 's/[[:blank:]]*$//g' | tr -s '[:space:]')"

    readarray -d "$delim" -s 1 -t columns < <(printf '%s' "$( echo -n "${prep_inputs}" | head -n 1)" )

    readarray -d ' ' -t myids < <(printf '%s' "$(while read l; do
        printf "${l}" | cut -d "$delim" -f 1
    done < <( echo "$prep_inputs" | tail -n +2 ) | tr '\n' ' ' | tr -s '[:space:]' )" )

    readarray -d '|' -t myarray < <(printf '%s' "$(while read l; do
        printf "${l}${delim}" | cut -d "$delim" -f 2-
    done < <( echo "$prep_inputs" | tail -n +2 ) | tr -d '\n' )" )

    local -i idx=0
    for id in "${myids[@]}"; do
        for col in "${columns[@]}"; do
            io::print_debug "$(printf "%18s " "[$id,$col]=${myarray[$idx]:-}")"
            if [[ "$col" != "value" ]] && [[ -n "${myarray["$idx"]:+set}" ]]; then
                io_parse_inputs_ref+=( ["$id","$col"]="${myarray["$idx"]}")
            elif [[ "$col" == "value" ]] && [[ -n "${myarray["$idx"]:+set}" ]]; then
                local -n io_parse_env_var="${myarray[$idx]}"
                if [[ -n "${io_parse_env_var:+set}" ]]; then
                    io_parse_inputs_ref+=( ["$id","$col"]="$(echo "${io_parse_env_var}" )" )
                fi
            fi
            ((idx+=1))
        done
        io::print_debug "$(printf "\n")"
    done
}
