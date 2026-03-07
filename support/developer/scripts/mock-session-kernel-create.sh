#!/bin/bash -x

SCRIPT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_PATH/common.sh"

ensure_mock_config_exists() {
    local profile="$1"
    if [ ! -f "/etc/mock/${profile}.cfg" ]; then
        log "Mock configuration for profile '$profile' does not exist. Please create it before running this script."
        exit 1
    fi
}

prepare_mock_install_build_requires() {
    local profile="$1"
    log "Preparing mock session for kernel build..."
    mock -r ${profile} --install \
        rpm-build \
        bc \
        bison \
        flex \
        elfutils-libelf-devel \
        openssl-devel \
        dwarves \
        rsync
}

prepare_mock_create_dirs() {
    local profile="$1"
    log "Preparing directories for bind mounting kernel source .."
    mock -r ${profile} \
        --chroot "mkdir -p /src/linux"
}

#
# Main
#

profile=${MOCK_PROFILE_KERNEL}

ensure_mock_config_exists ${profile}

mock -r ${profile} --init

prepare_mock_install_build_requires $profile

prepare_mock_create_dirs $profile
