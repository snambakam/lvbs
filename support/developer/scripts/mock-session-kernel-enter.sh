#!/bin/bash

SCRIPT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_PATH/common.sh"

#
# Main
#

KERNEL_TREE=$HOME/workspaces/linux

mock -r $MOCK_PROFILE_KERNEL \
     --enable-plugin=bind_mount \
     --plugin-option="bind_mount:dirs=[('$KERNEL_TREE','/src/linux')]" \
     --shell

