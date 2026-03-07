#!/bin/bash

set -euo pipefail

CYAN='\033[0;36m'
RESET='\033[0m'

MOCK_PROFILE_KERNEL=fedora-43-x86_64-kernel

function log() {
    timestamp="$(date "+%F %R:%S")"
    printf "%b\n" "${CYAN}+++ $timestamp $1${RESET}"
}
