#!/bin/bash

SCRIPTS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
. "$SCRIPTS_DIR/common.sh"

BUILD_ROOT="$SCRIPTS_DIR/build"
mkdir -p "$BUILD_ROOT"

if [ ! -f "$BUILD_ROOT/.config" ]; then
	cp $LINUX_KERNEL_CONFIG "$BUILD_ROOT/.config"
fi

make -C $LINUX_SRC_ROOT O="$BUILD_ROOT" olddefconfig
make -C $LINUX_SRC_ROOT O="$BUILD_ROOT" -j$(nproc)
make -C $LINUX_SRC_ROOT O="$BUILD_ROOT" -j$(nproc) modules
