#! /usr/bin/env nix-shell
#! nix-shell -i bash
#! nix-shell --pure
#! nix-shell --keep ENV1 --keep ENV2
#! nix-shell -p hello

set -Eeuo pipefail

help() (
    echo -e "\n~~~ Help for ${0##*/} ~~~"
    echo    "Explain what this script does and exit."
    echo    "Describes the nix-shell parameter and provides template for scripts."

    echo -e "\nExamples"
    echo    "- Print information about nix-shell parameters:"
    echo -e "    ${0##*/}\n"

    echo    "Required environment:"
    echo    "  - ENV1 variable"
    echo    "  - ENV2 variable"

    exit 1
)

requirements() (
    if [[ -z ${ENV1+x} ]]; then
        echo "ENV1 is not set. Aborting."
        return 1
    fi
    if [[ -z ${ENV2+x} ]]; then
        echo "ENV2 is not set. Aborting."
        return 1
    fi
    return 0
)

self() (
    if ! requirements || ( [[ $# -ge 1 ]] && [[ "$1" == "help" ]] ); then
        help
    fi

    echo "nix-shell"
    echo "      -i: provides interpreter, here bash."
    echo "  --pure: only packeges provided by -p are available + environment is cleaned."
    echo "  --keep: propagade the provided environment variable ENV1 to the nix-shell."
    echo "      -p: provide space separated list of dependencies. Here gnu hello."
    echo "You can split up nix-shell parameters across lines."
    echo "The parameters will be merged"
    hello
)

self $@
