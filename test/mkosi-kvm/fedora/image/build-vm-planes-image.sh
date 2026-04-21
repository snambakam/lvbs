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
VTL1_LOADER_SRC_DEFAULT="$SCRIPT_DIR/../../../../build/src/loader/lvbs-vtl1-pvh-shim.elf"
VTL0_KERNEL_SRC="${VTL0_KERNEL_SRC:-$VTL0_KERNEL_SRC_DEFAULT}"
VTL1_KERNEL_SRC="${VTL1_KERNEL_SRC:-$VTL1_KERNEL_SRC_DEFAULT}"
VTL1_LOADER_SRC="${VTL1_LOADER_SRC:-$VTL1_LOADER_SRC_DEFAULT}"

# Physical address where VTL1 should be loaded by the VTL0 launcher.
VTL1_LOAD_OFFSET_DEFAULT="0x40000000"
VTL1_LOAD_OFFSET="${VTL1_LOAD_OFFSET:-$VTL1_LOAD_OFFSET_DEFAULT}"

# Verified VTL1 execution must enter Plane 1.
VTL1_TARGET_PLANE_DEFAULT="1"
VTL1_TARGET_PLANE="${VTL1_TARGET_PLANE:-$VTL1_TARGET_PLANE_DEFAULT}"

VTL0_DEST_REL="usr/lib/lvbs/vtl0/vmlinuz"
VTL1_DEST_REL="usr/lib/lvbs/vtl1/vmlinux"
VTL1_LOADER_DEST_REL="usr/lib/lvbs/vtl1/loader.elf"
PLANES_CONF_REL="etc/lvbs/planes.conf"
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

if [ ! -f "$VTL1_LOADER_SRC" ]; then
	echo "Error: VTL1 loader ELF not found: $VTL1_LOADER_SRC"
	echo "Build it first (for example via build-vmlinux-bin-loader.sh) or set VTL1_LOADER_SRC."
	exit 1
fi

VTL0_KREL="$(make -s -C "$LINUX_SRC_ROOT" O="$VTL0_BUILD_DIR" kernelrelease)"
VTL1_KREL="$(make -s -C "$LINUX_SRC_ROOT" O="$VTL1_BUILD_DIR" kernelrelease)"

# Only clear generated plane artifacts so static files under mkosi.extra survive.
rm -rf "$MKOSI_EXTRA_DIR/usr/lib/lvbs/vtl0"
rm -rf "$MKOSI_EXTRA_DIR/usr/lib/lvbs/vtl1"
rm -rf "$MKOSI_EXTRA_DIR/usr/lib/modules"
rm -f "$MKOSI_EXTRA_DIR/$PLANES_CONF_REL"
rm -f "$MKOSI_EXTRA_DIR/$DRACUT_CONF_REL"

mkdir -p "$(dirname "$MKOSI_EXTRA_DIR/$VTL0_DEST_REL")"
mkdir -p "$(dirname "$MKOSI_EXTRA_DIR/$VTL1_DEST_REL")"
mkdir -p "$(dirname "$MKOSI_EXTRA_DIR/$VTL1_LOADER_DEST_REL")"
mkdir -p "$(dirname "$MKOSI_EXTRA_DIR/$PLANES_CONF_REL")"
mkdir -p "$(dirname "$MKOSI_EXTRA_DIR/$DRACUT_CONF_REL")"

cp -f "$VTL0_KERNEL_SRC" "$MKOSI_EXTRA_DIR/$VTL0_DEST_REL"
cp -f "$VTL1_KERNEL_SRC" "$MKOSI_EXTRA_DIR/$VTL1_DEST_REL"
cp -f "$VTL1_LOADER_SRC" "$MKOSI_EXTRA_DIR/$VTL1_LOADER_DEST_REL"

echo "$VTL0_KREL" > "$MKOSI_EXTRA_DIR/usr/lib/lvbs/vtl0/kernelrelease"
echo "$VTL1_KREL" > "$MKOSI_EXTRA_DIR/usr/lib/lvbs/vtl1/kernelrelease"

echo "Installing VTL0 kernel modules into mkosi.extra for UKI initrd generation..."
make -s -C "$LINUX_SRC_ROOT" O="$VTL0_BUILD_DIR" \
	INSTALL_MOD_PATH="$MKOSI_EXTRA_DIR/usr" modules_install

VTL0_SHA256="$(sha256sum "$MKOSI_EXTRA_DIR/$VTL0_DEST_REL" | awk '{print $1}')"
VTL1_SHA256="$(sha256sum "$MKOSI_EXTRA_DIR/$VTL1_DEST_REL" | awk '{print $1}')"
VTL1_LOADER_SHA256="$(sha256sum "$MKOSI_EXTRA_DIR/$VTL1_LOADER_DEST_REL" | awk '{print $1}')"

cat > "$MKOSI_EXTRA_DIR/$PLANES_CONF_REL" <<EOF
# LVBS VM Plane kernel layout
# Plane 0 / VTL0: regular kernel (compressed bzImage)
# Plane 1 / VTL1: secure kernel (uncompressed vmlinux)
LVBS_VTL0_KERNEL=/$VTL0_DEST_REL
LVBS_VTL1_KERNEL=/$VTL1_DEST_REL
LVBS_VTL1_LOADER=/$VTL1_LOADER_DEST_REL
LVBS_VTL0_KERNELRELEASE=$VTL0_KREL
LVBS_VTL1_KERNELRELEASE=$VTL1_KREL
LVBS_VTL0_SHA256=$VTL0_SHA256
LVBS_VTL1_SHA256=$VTL1_SHA256
LVBS_VTL1_LOADER_SHA256=$VTL1_LOADER_SHA256
LVBS_VTL0_TYPE=bzImage
LVBS_VTL1_TYPE=vmlinux
LVBS_VTL1_TARGET_PLANE=$VTL1_TARGET_PLANE
LVBS_VTL1_LOAD_OFFSET=$VTL1_LOAD_OFFSET
EOF

cat > "$MKOSI_EXTRA_DIR/$DRACUT_CONF_REL" <<EOF
# Embed the secure-plane kernel payload and plane metadata into the initrd.
install_items+=" /$VTL1_DEST_REL /$PLANES_CONF_REL "
EOF

echo "[INSTRUMENTATION] Kernel verification details:"
echo "[INSTRUMENTATION] VTL0 kernel (compressed bzImage):"
echo "[INSTRUMENTATION]   Size: $(stat -c%s "$MKOSI_EXTRA_DIR/$VTL0_DEST_REL") bytes"
echo "[INSTRUMENTATION]   SHA256: $VTL0_SHA256"
echo "[INSTRUMENTATION] VTL1 kernel (uncompressed vmlinux):"
echo "[INSTRUMENTATION]   Size: $(stat -c%s "$MKOSI_EXTRA_DIR/$VTL1_DEST_REL") bytes"
echo "[INSTRUMENTATION]   SHA256: $VTL1_SHA256"
echo "[INSTRUMENTATION] VTL1 loader (prebuilt ELF):"
echo "[INSTRUMENTATION]   Source: $VTL1_LOADER_SRC"
echo "[INSTRUMENTATION]   Size: $(stat -c%s "$MKOSI_EXTRA_DIR/$VTL1_LOADER_DEST_REL") bytes"
echo "[INSTRUMENTATION]   SHA256: $VTL1_LOADER_SHA256"
echo "[INSTRUMENTATION]   Target plane: $VTL1_TARGET_PLANE"
echo "[INSTRUMENTATION]   Load offset: $VTL1_LOAD_OFFSET"

echo "[INSTRUMENTATION] planes.conf generated:"
cat "$MKOSI_EXTRA_DIR/$PLANES_CONF_REL"

echo ""
echo "========== KERNEL STAGING SUMMARY =========="
echo "Staged kernels for image build:"
echo "  VTL0 (Plane 0 - compressed bzImage): $VTL0_KERNEL_SRC -> /$VTL0_DEST_REL"
echo "  VTL1 (Plane 1 - uncompressed vmlinux): $VTL1_KERNEL_SRC -> /$VTL1_DEST_REL"
echo "  VTL1 loader (Plane 1 entry ELF): $VTL1_LOADER_SRC -> /$VTL1_LOADER_DEST_REL"
echo "    Target plane: $VTL1_TARGET_PLANE"
echo "    Load offset: $VTL1_LOAD_OFFSET"
echo "  VTL0 kernelrelease: $VTL0_KREL"
echo "  VTL1 kernelrelease: $VTL1_KREL"
echo "  VTL0 SHA256: $VTL0_SHA256"
echo "  VTL1 SHA256: $VTL1_SHA256"
echo "  VTL1 loader SHA256: $VTL1_LOADER_SHA256"
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
echo "Kernel mapping inside image:"
echo "  /$VTL0_DEST_REL (VTL0 / Plane 0 - compressed)"
echo "  /$VTL1_DEST_REL (VTL1 / Plane 1 - uncompressed)"
echo ""
echo "EXPECTED BOOT FLOW:"
echo "  1. UEFI firmware -> systemd-stub (UKI with VTL0 bzImage kernel)"
echo "  2. VTL0 kernel + initrd boot"
echo "  3. Initrd contains embedded VTL1 uncompressed vmlinux (/$VTL1_DEST_REL)"
echo "  4. VTL0 init should verify VTL1 kernel SHA256: $VTL1_SHA256"
echo "  5. VTL0 init should load VTL1 kernel at offset $VTL1_LOAD_OFFSET"
echo "  6. VTL0 init should place the verified VTL1 kernel into Plane $VTL1_TARGET_PLANE"
echo "  7. VTL0 init should launch VTL1 kernel via hypercall"
echo ""
echo "VERIFICATION: Check /etc/lvbs/planes.conf inside image for plane configuration"
