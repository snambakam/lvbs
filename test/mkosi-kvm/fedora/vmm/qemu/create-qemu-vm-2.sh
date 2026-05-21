#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE_DIR="$SCRIPT_DIR/../../image"

CONSOLE="-nographic"
BIOS="/usr/share/edk2/ovmf/OVMF_CODE_4M.qcow2"
SERIAL_CONSOLE="-serial mon:stdio"

# Ensure OVMF variables file is present and up to date
"$SCRIPT_DIR/get-firmware-vars.sh"

qemu-system-x86_64 \
	-enable-kvm \
	-machine q35 \
	-cpu host \
	-m 2G \
	-smp 1 \
	-drive file="$IMAGE_DIR/fedora-kvm.raw",format=raw,if=virtio \
	-drive if=pflash,format=qcow2,readonly=on,file=$BIOS \
	-drive if=pflash,format=qcow2,file="$IMAGE_DIR/OVMF_VARS_4M.qcow2" \
	$SERIAL_CONSOLE
