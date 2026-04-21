#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE_DIR="$SCRIPT_DIR/../image"

CONSOLE="-nographic"
SERIAL_CONSOLE="-serial mon:stdio"
qemu-system-x86_64 \
	-enable-kvm \
	-machine q35 \
	-cpu host \
	-m 2G \
	-smp 1 \
	-drive file="$IMAGE_DIR/fedora-kvm.raw",format=raw,if=virtio \
	-bios /usr/share/OVMF/OVMF_CODE.fd \
	$SERIAL_CONSOLE

