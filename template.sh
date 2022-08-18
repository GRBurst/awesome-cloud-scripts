#! /usr/bin/env nix-shell
#! nix-shell -i bash
#! nix-shell --pure
#! nix-shell --keep ENV1 --keep ENV2
#! nix-shell -p hello

set -Eeuo pipefail

help() (
    echo "${0##*/}"
    echo "Explain what this script does and exit."
    echo "Describes the nix-shell parameter and provides template for scripts."
    exit 1
)

self() (
    if [[ $# -ge 1 ]] && [[ "$1" == "help" ]]; then
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
