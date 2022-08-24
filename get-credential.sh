#! /usr/bin/env nix-shell
#! nix-shell -i bash
#! nix-shell --pure
#! nix-shell --keep AWS_PROFILE
#! nix-shell -p awscli2 aws-vault jq fzf xclip

# https://vaneyckt.io/posts/safer_bash_scripts_with_set_euxo_pipefail
set -Eeuo pipefail

# cd to script location
cd "$(dirname "${BASH_SOURCE[0]}")"

source .lib.sh

# Configure your parameters here. The provided 
declare -A get_credentials_params=(
    [p,arg]="--profile" [p,value]="${AWS_PROFILE:-}" [p,short]="-p" [p,required]=true  [p,name]="aws profile"
)
# We will add boolean switches like --bool to this
declare -a get_credentials_bool_switches


# Define your usage and help message here
usage() (
    local script_name="${0##*/}"
    cat <<-USAGE

$script_name consists of 2 parts:
  1. Let user choose a secret by name.
  2. Get the secret and copy it to your clipboard.


Usage and Examples
-----

- Choose and copy an aws secret to your clipboard::
    $script_name


Arguments and Environment
---------

Required environment:
  - AWS_PROFILE variable or argument -p | --profile

USAGE

    exit 1
)

# Process your parameters here
configure() {
    while [ "${1:-}" != "" ]; do
        case $1 in
        -p | --profile)
            shift
            assign get_credentials_params p ${1:-} || usage
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
    # Use the parameter string or access the template_aws_params yourself
    local paramstr="${1:-}"

    secret_name="$(aws secretsmanager list-secrets $paramstr | jq -r '.SecretList | .[].Name' | fzf)"
    aws secretsmanager $paramstr get-secret-value --version-stage AWSCURRENT --secret-id "$secret_name" | jq -r '.SecretString | fromjson | .password' | xclip
)

self() (
    declare -a args=$@
    if ! (check_requirements args get_credentials_params) || [[ "${1:-}" == "help" ]]; then
        usage
    else
        if (($# > 0)); then
            configure $args
        fi

        local paramstr="$(translate_args get_credentials_params get_credentials_bool_switches)"
        run "$paramstr"
    fi

)

self $@
