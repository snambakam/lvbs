#!/bin/bash

SCRIPT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_PATH/common.sh"

#
# Main
#

profile=${MOCK_PROFILE_KERNEL}

mock -r $profile --scrub all

