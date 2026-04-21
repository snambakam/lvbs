#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

IMAGE_DIR="$SCRIPT_DIR/../image"

PLANE0_DISK="${PLANE0_DISK:-$IMAGE_DIR/fedora-kvm.raw}"
ENABLE_PLANES="${ENABLE_PLANES:-1}"
MEMORY_SIZE="${MEMORY_SIZE:-2G}"
SMP="${SMP:-3}"
SERIAL_LOG_FILE="${SERIAL_LOG_FILE:-/tmp/plane-serial.log}"
BIOS="${BIOS:-/usr/share/OVMF/OVMF_CODE_4M.fd}"
OVMF_VARS="${OVMF_VARS:-$IMAGE_DIR/OVMF_VARS_4M.fd}"

for required_file in "$PLANE0_DISK" "$BIOS" "$OVMF_VARS"; do
    if [[ ! -f "$required_file" ]]; then
        echo "Missing required file: $required_file" >&2
        exit 1
    fi
done

PLANE_ARGS=()
if [[ "$ENABLE_PLANES" == "1" ]]; then
    PLANE_ARGS+=(-enable-planes)
fi

echo "Launching QEMU with VM planes (UKI secure boot):"
echo "  Disk image:       $PLANE0_DISK"
echo "  OVMF firmware:    $BIOS"
echo "  OVMF variables:   $OVMF_VARS"
echo "  Memory:           $MEMORY_SIZE"
echo "  SMP:              $SMP"
echo "  Planes:           $(if [[ "$ENABLE_PLANES" == "1" ]]; then echo enabled; else echo disabled; fi)"
echo "  Serial output:    $SERIAL_LOG_FILE"

if ! command -v qemu-system-x86_64 >/dev/null 2>&1; then
    echo "qemu-system-x86_64 was not found in PATH." >&2
    echo "PATH=$PATH" >&2
    exit 127
fi

qemu-system-x86_64 \
    -enable-kvm \
    -machine q35 \
    -cpu host \
    -m "$MEMORY_SIZE" \
    -smp "$SMP" \
    -nographic \
    -drive file="$PLANE0_DISK",format=raw,if=virtio \
    -drive if=pflash,format=raw,readonly=on,file="$BIOS" \
    -drive if=pflash,format=raw,file="$OVMF_VARS" \
    -serial file="$SERIAL_LOG_FILE" \
    "${PLANE_ARGS[@]}"
