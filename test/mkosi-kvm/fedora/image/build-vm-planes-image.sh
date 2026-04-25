#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

LINUX_SRC_ROOT_DEFAULT="$HOME/workspaces/linux"
LINUX_SRC_ROOT="${LINUX_SRC_ROOT:-$LINUX_SRC_ROOT_DEFAULT}"

VTL0_BUILD_DIR_DEFAULT="$SCRIPT_DIR/../../../kernel/build"
VTL1_BUILD_DIR_DEFAULT="$SCRIPT_DIR/../../../kernel/build-sk"
VTL0_BUILD_DIR="${VTL0_BUILD_DIR:-$VTL0_BUILD_DIR_DEFAULT}"
VTL1_BUILD_DIR="${VTL1_BUILD_DIR:-$VTL1_BUILD_DIR_DEFAULT}"

# VTL0 uses a compressed bzImage, VTL1 uses an uncompressed vmlinux payload.
VTL0_KERNEL_SRC_DEFAULT="$VTL0_BUILD_DIR/arch/x86/boot/bzImage"
VTL1_KERNEL_SRC_DEFAULT="$VTL1_BUILD_DIR/vmlinux"
VTL0_KERNEL_SRC="${VTL0_KERNEL_SRC:-$VTL0_KERNEL_SRC_DEFAULT}"
VTL1_KERNEL_SRC="${VTL1_KERNEL_SRC:-$VTL1_KERNEL_SRC_DEFAULT}"

# Physical address where VTL1 should be loaded by the VTL0 launcher.
VTL1_LOAD_OFFSET_DEFAULT="0x40000000"
VTL1_LOAD_OFFSET="${VTL1_LOAD_OFFSET:-$VTL1_LOAD_OFFSET_DEFAULT}"

# Verified VTL1 execution must enter Plane 1.
VTL1_TARGET_PLANE_DEFAULT="1"
VTL1_TARGET_PLANE="${VTL1_TARGET_PLANE:-$VTL1_TARGET_PLANE_DEFAULT}"
VTL1_VCPU_COUNT_DEFAULT="1"
VTL1_VCPU_COUNT="${VTL1_VCPU_COUNT:-$VTL1_VCPU_COUNT_DEFAULT}"
VTL1_MEMORY_SIZE_DEFAULT="0x02000000"
VTL1_MEMORY_SIZE="${VTL1_MEMORY_SIZE:-$VTL1_MEMORY_SIZE_DEFAULT}"

VTL1_INITRD_DEST_REL="boot/plane-${VTL1_TARGET_PLANE}/vmlinux"
CONFIG_VM_PLANES_REL="config-vm-planes"
DRACUT_CONF_REL="etc/dracut.conf.d/50-lvbs-vtl1.conf"
MKOSI_EXTRA_DIR="$SCRIPT_DIR/mkosi.extra"

if ! command -v mkosi >/dev/null 2>&1; then
	echo "Error: mkosi is not installed or not in PATH"
	echo "Install it first, then re-run this script."
	exit 1
fi

if [ ! -d "$LINUX_SRC_ROOT" ]; then
	echo "Error: Linux source root not found: $LINUX_SRC_ROOT"
	echo "Set LINUX_SRC_ROOT and re-run."
	exit 1
fi

if [ ! -f "$VTL0_KERNEL_SRC" ]; then
	echo "Error: VTL0 kernel not found: $VTL0_KERNEL_SRC"
	exit 1
fi

if [ ! -f "$VTL1_KERNEL_SRC" ]; then
	echo "Error: VTL1 kernel not found: $VTL1_KERNEL_SRC"
	exit 1
fi

VTL0_KREL="$(make -s -C "$LINUX_SRC_ROOT" O="$VTL0_BUILD_DIR" kernelrelease)"
VTL1_KREL="$(make -s -C "$LINUX_SRC_ROOT" O="$VTL1_BUILD_DIR" kernelrelease)"

# Only clear generated plane artifacts so static files under mkosi.extra survive.
rm -rf "$MKOSI_EXTRA_DIR/usr/lib/lvbs"
rm -rf "$MKOSI_EXTRA_DIR/usr/lib/modules"
rm -rf "$MKOSI_EXTRA_DIR/boot/plane-${VTL1_TARGET_PLANE}"
rm -f "$MKOSI_EXTRA_DIR/$CONFIG_VM_PLANES_REL"
rm -f "$MKOSI_EXTRA_DIR/etc/lvbs/config-vm-planes"
rm -f "$MKOSI_EXTRA_DIR/$DRACUT_CONF_REL"

mkdir -p "$(dirname "$MKOSI_EXTRA_DIR/$VTL1_INITRD_DEST_REL")"
mkdir -p "$(dirname "$MKOSI_EXTRA_DIR/$CONFIG_VM_PLANES_REL")"
mkdir -p "$(dirname "$MKOSI_EXTRA_DIR/$DRACUT_CONF_REL")"

cp -f "$VTL1_KERNEL_SRC" "$MKOSI_EXTRA_DIR/$VTL1_INITRD_DEST_REL"

echo "Installing VTL0 kernel modules into mkosi.extra for UKI initrd generation..."
make -s -C "$LINUX_SRC_ROOT" O="$VTL0_BUILD_DIR" \
	INSTALL_MOD_PATH="$MKOSI_EXTRA_DIR/usr" modules_install

VTL0_SHA256="$(sha256sum "$VTL0_KERNEL_SRC" | cut -d' ' -f1)"
VTL1_SHA256="$(sha256sum "$MKOSI_EXTRA_DIR/$VTL1_INITRD_DEST_REL" | cut -d' ' -f1)"

cat > "$MKOSI_EXTRA_DIR/$CONFIG_VM_PLANES_REL" <<EOF
# VM Planes configuration consumed by linux/init/vm_planes.c
PLANE_COUNT=2
PLANE_${VTL1_TARGET_PLANE}_LOAD_OFFSET=$VTL1_LOAD_OFFSET
PLANE_${VTL1_TARGET_PLANE}_MEMORY_SIZE=$VTL1_MEMORY_SIZE
PLANE_${VTL1_TARGET_PLANE}_VCPU_COUNT=$VTL1_VCPU_COUNT
PLANE_${VTL1_TARGET_PLANE}_KERNEL=/$VTL1_INITRD_DEST_REL
EOF

cat > "$MKOSI_EXTRA_DIR/$DRACUT_CONF_REL" <<EOF
# Embed the secure-plane kernel payload and VM planes config into the initrd.
install_items+=" /$VTL1_INITRD_DEST_REL /$CONFIG_VM_PLANES_REL "
EOF

echo "[INSTRUMENTATION] Kernel verification details:"
echo "[INSTRUMENTATION] VTL0 kernel (compressed bzImage):"
echo "[INSTRUMENTATION]   Source: $VTL0_KERNEL_SRC"
echo "[INSTRUMENTATION]   Size: $(stat -c%s "$VTL0_KERNEL_SRC") bytes"
echo "[INSTRUMENTATION]   SHA256: $VTL0_SHA256"
echo "[INSTRUMENTATION] VTL1 kernel (uncompressed vmlinux):"
echo "[INSTRUMENTATION]   Source: $VTL1_KERNEL_SRC"
echo "[INSTRUMENTATION]   Initrd path: /$VTL1_INITRD_DEST_REL"
echo "[INSTRUMENTATION]   Size: $(stat -c%s "$MKOSI_EXTRA_DIR/$VTL1_INITRD_DEST_REL") bytes"
echo "[INSTRUMENTATION]   SHA256: $VTL1_SHA256"
echo "[INSTRUMENTATION]   Target plane: $VTL1_TARGET_PLANE"
echo "[INSTRUMENTATION]   Load offset: $VTL1_LOAD_OFFSET"

echo "[INSTRUMENTATION] config-vm-planes generated:"
cat "$MKOSI_EXTRA_DIR/$CONFIG_VM_PLANES_REL"

echo ""
echo "========== KERNEL STAGING SUMMARY =========="
echo "Staged kernels for image build:"
echo "  VTL0 source kernel (Plane 0 - compressed bzImage): $VTL0_KERNEL_SRC"
echo "  VTL1 source kernel (Plane 1 - uncompressed vmlinux): $VTL1_KERNEL_SRC"
echo "  VTL1 staged for initrd: $VTL1_KERNEL_SRC -> /$VTL1_INITRD_DEST_REL"
echo "    Target plane: $VTL1_TARGET_PLANE"
echo "    Load offset: $VTL1_LOAD_OFFSET"
echo "    Memory size: $VTL1_MEMORY_SIZE"
echo "    vCPU count: $VTL1_VCPU_COUNT"
echo "  VTL0 kernelrelease: $VTL0_KREL"
echo "  VTL1 kernelrelease: $VTL1_KREL"
echo "  VTL0 SHA256: $VTL0_SHA256"
echo "  VTL1 SHA256: $VTL1_SHA256"
echo ""
echo "[INSTRUMENTATION] Dracut configuration for VTL1 embedding:"
cat "$MKOSI_EXTRA_DIR/$DRACUT_CONF_REL"
echo ""
echo "Building fedora-kvm.raw with mkosi..."
(
	cd "$SCRIPT_DIR"
	mkosi --force build
)

echo ""
echo "========== BUILD COMPLETE =========="
echo "Build complete: $SCRIPT_DIR/fedora-kvm.raw"
echo "Plane kernel payloads embedded in initrd:"
echo "  /$VTL1_INITRD_DEST_REL (VTL1 / Plane 1 - uncompressed)"
echo ""
echo "EXPECTED BOOT FLOW:"
echo "  1. UEFI firmware -> systemd-stub (UKI with VTL0 bzImage kernel)"
echo "  2. VTL0 kernel + initrd boot"
echo "  3. Initrd contains embedded VTL1 uncompressed vmlinux (/$VTL1_INITRD_DEST_REL)"
echo "     and VM planes config (/$CONFIG_VM_PLANES_REL)"
echo "  4. VTL0 init should verify VTL1 kernel SHA256: $VTL1_SHA256"
echo "  5. VTL0 init should load VTL1 kernel at offset $VTL1_LOAD_OFFSET"
echo "  6. VTL0 init should place the verified VTL1 kernel into Plane $VTL1_TARGET_PLANE"
echo "  7. VTL0 init should launch the Plane $VTL1_TARGET_PLANE kernel via hypercall"
echo ""
echo "VERIFICATION: Check /config-vm-planes inside the initrd for plane configuration"
