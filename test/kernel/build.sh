#!/bin/bash

SCRIPTS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
. "$SCRIPTS_DIR/common.sh"


build() {
	if [ ! -f "$BUILD_ROOT/.config" ]; then
		# Find the latest Fedora kernel config as the base
		local host_config="$LINUX_KERNEL_CONFIG"
		if [ ! -f "$host_config" ]; then
			host_config=$(ls -t /boot/config-* 2>/dev/null | head -1)
		fi
		if [ -z "$host_config" ] || [ ! -f "$host_config" ]; then
			echo "Error: No kernel config found"
			exit 1
		fi
		echo "Using base config: $host_config"
		cp "$host_config" "$BUILD_ROOT/.config"
	fi

	if ! grep -q "^CONFIG_VM_PLANES=y" "$BUILD_ROOT/.config"; then
		sed -i '/^# CONFIG_VM_PLANES is not set/d' "$BUILD_ROOT/.config"
		echo "CONFIG_VM_PLANES=y" >> "$BUILD_ROOT/.config"
	fi

	if ! grep -q "^CONFIG_VBS=y" "$BUILD_ROOT/.config"; then
		sed -i '/^# CONFIG_VBS is not set/d' "$BUILD_ROOT/.config"
		echo "CONFIG_VBS=y" >> "$BUILD_ROOT/.config"
	fi

	if ! grep -q "^CONFIG_VBS_KVM_PLANES=y" "$BUILD_ROOT/.config"; then
		sed -i '/^# CONFIG_VBS_KVM_PLANES is not set/d' "$BUILD_ROOT/.config"
		echo "CONFIG_VBS_KVM_PLANES=y" >> "$BUILD_ROOT/.config"
	fi

	if ! grep -q "^CONFIG_BPF_LSM=y" "$BUILD_ROOT/.config"; then
		sed -i '/^# CONFIG_BPF_LSM is not set/d' "$BUILD_ROOT/.config"
		echo "CONFIG_BPF_LSM=y" >> "$BUILD_ROOT/.config"
	fi

	if ! grep -q "^CONFIG_DEBUG_INFO_BTF=y" "$BUILD_ROOT/.config"; then
		sed -i '/^# CONFIG_DEBUG_INFO_BTF is not set/d' "$BUILD_ROOT/.config"
		echo "CONFIG_DEBUG_INFO_BTF=y" >> "$BUILD_ROOT/.config"
	fi

	if ! grep -q "^CONFIG_BPF_JIT=y" "$BUILD_ROOT/.config"; then
		sed -i '/^# CONFIG_BPF_JIT is not set/d' "$BUILD_ROOT/.config"
		echo "CONFIG_BPF_JIT=y" >> "$BUILD_ROOT/.config"
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

