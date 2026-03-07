#!/bin/bash

SCRIPT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_PATH/common.sh"

ensure_mock_config_exists() {
    local profile="$1"
    if [ ! -f "/etc/mock/${profile}.cfg" ]; then
        log "Mock configuration for profile '$profile' does not exist. Creating it..."
	sudo cp "$SCRIPT_PATH/../config/$profile.cfg" /etc/mock/
    fi
}

#
# Main
#

profile=${MOCK_PROFILE_KERNEL}

ensure_mock_config_exists ${profile}

