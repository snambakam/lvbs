#!/bin/bash

SCRIPTS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
. "$SCRIPTS_DIR/common.sh"

BUILD_ROOT="$SCRIPTS_DIR/build-sk"
mkdir -p "$BUILD_ROOT"

if [ ! -f "$BUILD_ROOT/.config" ]; then
	make -C $LINUX_SRC_ROOT O="$BUILD_ROOT" x86_64_defconfig
fi

if ! grep -q '^CONFIG_X86_64=y$' "$BUILD_ROOT/.config"; then
	echo "[build-sk] Existing config is not x86_64; regenerating x86_64_defconfig"
	make -C $LINUX_SRC_ROOT O="$BUILD_ROOT" x86_64_defconfig
fi

set_kconfig_bool() {
	local key="$1"
	local value="$2"
	sed -i \
		-e "/^${key}=.*/d" \
		-e "/^# ${key} is not set/d" \
		"$BUILD_ROOT/.config"
	echo "${key}=${value}" >> "$BUILD_ROOT/.config"
}

# Ensure 64-bit x86 architecture (disable 32-bit, enable 64-bit)
set_kconfig_bool CONFIG_X86_32 n
set_kconfig_bool CONFIG_X86_64 y
set_kconfig_bool CONFIG_64BIT y

# Plane 1 needs guest/paravirt boot support; otherwise CH can reset-loop Plane 1.
set_kconfig_bool CONFIG_HYPERVISOR_GUEST y
set_kconfig_bool CONFIG_PARAVIRT y
set_kconfig_bool CONFIG_KVM_GUEST y
set_kconfig_bool CONFIG_PVH y
set_kconfig_bool CONFIG_XEN_PVH y

# Embed a minimal initramfs so Plane 1 can boot without an external rootfs.
# The initramfs contains a statically linked /init that keeps the kernel running.
INITRAMFS_DIR="$SCRIPTS_DIR/initramfs-sk"
mkdir -p "$INITRAMFS_DIR"/{dev,proc,sys}

# Build a static init binary (no libc dependency)
gcc -nostdlib -static -o "$INITRAMFS_DIR/init" "$INITRAMFS_DIR/init.c"
if [ $? -ne 0 ]; then
    echo "[build-sk] Failed to compile static init"
    exit 1
fi

set_kconfig_bool CONFIG_BLK_DEV_INITRD y
sed -i \
    -e '/^CONFIG_INITRAMFS_SOURCE=.*/d' \
    "$BUILD_ROOT/.config"
echo "CONFIG_INITRAMFS_SOURCE=\"$INITRAMFS_DIR\"" >> "$BUILD_ROOT/.config"

make -C $LINUX_SRC_ROOT O="$BUILD_ROOT" olddefconfig

make -C $LINUX_SRC_ROOT O="$BUILD_ROOT" -j$(nproc)
make -C $LINUX_SRC_ROOT O="$BUILD_ROOT" -j$(nproc) modules
objcopy -O binary -R .note -R .comment -S "$BUILD_ROOT/vmlinux" "$BUILD_ROOT/vmlinux.bin"
