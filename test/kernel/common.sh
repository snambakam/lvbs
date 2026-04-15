#!/bin/bash

SOURCE_FOLDER="$(realpath $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/..)"
LINUX_SRC_ROOT=
if [ -d $HOME/workspaces/linux ]; then
	LINUX_SRC_ROOT=$HOME/workspaces/linux
fi
LINUX_KERNEL_CONFIG=/boot/config-$(uname -r)
BUILD_ROOT=
