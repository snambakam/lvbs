#!/bin/bash

SCRIPTS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
. "$SCRIPTS_DIR/common.sh"


build() {
	if [ ! -f "$BUILD_ROOT/.config" ]; then
		cp $LINUX_KERNEL_CONFIG "$BUILD_ROOT/.config"
	fi

	make -C $LINUX_SRC_ROOT O="$BUILD_ROOT" olddefconfig
	make -C $LINUX_SRC_ROOT O="$BUILD_ROOT" -j$(nproc)
	make -C $LINUX_SRC_ROOT O="$BUILD_ROOT" -j$(nproc) modules
}

install() {
	sudo make -C $LINUX_SRC_ROOT O="$BUILD_ROOT" modules_install
	sudo make -C $LINUX_SRC_ROOT O="$BUILD_ROOT" install
}

#
# Main
#

BUILD_ROOT="$SCRIPTS_DIR/build"
mkdir -p "$BUILD_ROOT"

CMD="build"
if [ $# -gt 0 ]; then
	CMD="$1"
fi

case "$CMD" in
	"build")
		build
		;;
	"install")
		install
		;;
	*)
		echo "Error: unrecognized command - $CMD"
		exit 1
		;;
esac

