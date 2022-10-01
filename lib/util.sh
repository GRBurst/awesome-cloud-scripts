#! /usr/bin/env bash
set -Eeuo pipefail

declare -x SCRIPT_COOK_UTIL_LOADED=true

util::wait_for_func() {
    local func_ref=$1
    local term_condition="$2"
    local desc="${3:+"for $3"}"
    local -n res="${4:-dummy}"
    local -i interval="${5:-1}"
    local -i max_duration="${6:-0}"

    local -i n

    n=1
    printf "Waiting $3"
    while [[ "$( $func_ref )" != "$2" ]] && ( (( max_duration == 0 )) || (( n*interval <= max_duration )) ); do
        if (( n%10 == 0)); then
            printf "\rWaiting $3"
        fi
        printf "."
        (( n+=1 ))
        sleep $interval
    done
    printf " completed ($n tries)\n"
}

util::wait_for_func_not() {
    local func_ref=$1
    local term_condition="$2"
    local desc="${3:+"for $3"}"
    local -n res="${4:-dummy}"
    local -i interval="${5:-1}"
    local -i max_duration="${6:-0}"

    local -i n

    n=1
    printf "Waiting $3"
    while [[ "$( $func_ref )" != "$2" ]] && ( (( max_duration == 0 )) || (( n*interval <= max_duration )) ); do
        if (( n%10 == 0)); then
            printf "\rWaiting $3"
        fi
        printf "."
        (( n+=1 ))
        sleep $interval
    done
    printf " completed ($n tries)\n"
}
