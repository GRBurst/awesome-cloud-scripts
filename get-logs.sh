#! /usr/bin/env nix-shell
#! nix-shell -i bash
#! nix-shell --pure
#! nix-shell --keep AWS_PROFILE
#! nix-shell -p awscli2 aws-vault
#! nix-shell -p awslogs fzf

# https://vaneyckt.io/posts/safer_bash_scripts_with_set_euxo_pipefail
set -Eeuo pipefail

# cd to script location
cd "$(dirname "${BASH_SOURCE[0]}")"

source .lib.sh


# Configure your parameters here. The provided 
declare -A get_logs_options=(
    [p,arg]="--profile" [p,value]="${AWS_PROFILE:-}" [p,short]="-p" [p,required]=true  [p,name]="aws profile"
    [s,arg]="--start"                                [s,short]="-s" [s,required]=false [s,name]="start position"
)
# This will contain the resulting parameters of your command
declare -A get_logs_params

# Define your usage and help message here
usage() (
    local script_name="${0##*/}"
    cat <<-USAGE

Choose an aws log group and watch the logs.


Usage and Examples
-----

- Choose aws log group and the logs:
    $script_name


Arguments and Environment
---------

Required environment:
  - AWS_PROFILE variable or argument -p | --profile

Optional arguments:
  -s | --start

USAGE

    exit 1
)

# Process your parameters here
configure() {
    while [ "${1:-}" != "" ]; do
        case $1 in
        -p | --profile)
            shift
            # assign takes:
            # 1. parameter array
            # 2. first variable key (we used [p,*] before)
            # 3. variable value
            assign get_logs_options p ${1:-} || usage
            ;;
        -s | --start)
            shift
            assign get_logs_options s ${1:-} || usage
            ;;
        -h | --help)
            shift
            usage
            ;;
        esac
        shift
    done
}

# Put your script logic here
run() (
    # Use the parameter string or access the get_logs_options yourself
    # local paramstr=${get_logs_options[paramstr]:-}
    local groups_paramstr="${get_logs_options[p,str]:-}"

    # local -a paramstr=(${get_logs_options[paramstr]:-})
    # read -a paramstr <<< ${get_logs_options[paramstr]}
    local -a paramstr=("$(echo "${get_logs_options[paramstr]}" | sed -e 's/^[[:space:]]*//')")
    read -a paramstr <<< $(echo "${get_logs_options[paramstr]}" | sed -e 's/^[[:space:]]*//')

    # awslogs groups "${get_logs_options[paramstr]:-}"
    # awslogs groups "$groups_paramstr"
    echo "elements ${#paramstr[@]}"
    for e in "${paramstr[@]}"; do
        echo "e = $e"
    done

    # (awslogs groups "${paramstr[@]}")

    # echo "awslogs groups $paramstr"
    # awslogs groups "${paramstr[@]}"

    # local group=$(eval "awslogs groups $groups_paramstr" | fzf)
    # if [ -n "$group" ]; then
    #     eval "awslogs get --watch $group --no-group --no-stream $paramstr"
    # fi

    # local t="$(echo $groups_paramstr)"
    # echo $1
    # echo $paramstr
    # awslogs groups $1
    # awslogs get ALL --no-group --no-stream $1
    # local group=$(awslogs groups $groups_paramstr | fzf)
    # if [ -n "$group" ]; then
    #     awslogs get --watch $group --no-group --no-stream $paramstr
    # fi
)


# This is the base frame and it shouldn't be necessary to touch it
self() (
    declare -a args=$@
    if ! (check_requirements args get_logs_options) || [[ "${1:-}" == "help" ]]; then
        usage
    else
        if (($# > 0)); then
            configure $args
        fi

        translate_args get_logs_options
        # echo "now ${get_logs_options[paramstr]}"

        # local p=$(echo "${get_logs_options[paramstr]}")
        # run "$p"
        run
    fi

)

self $@
