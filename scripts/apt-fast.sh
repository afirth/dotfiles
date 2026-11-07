#!/usr/bin/env bash
# Bootstrap apt-fast on Ubuntu only when a package operation actually needs it.
set -euo pipefail

if ! command -v apt-fast >/dev/null 2>&1; then
    sudo apt-get update
    sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y software-properties-common
    sudo add-apt-repository --yes ppa:apt-fast/stable
    sudo apt-get update
    sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y apt-fast
fi

exec sudo apt-fast "$@"
