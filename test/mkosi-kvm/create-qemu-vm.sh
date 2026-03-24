#!/bin/bash

CONSOLE="-nographic"
SERIAL_CONSOLE="-serial mon:stdio"
qemu-system-x86_64 \
	-enable-kvm \
	-machine q35 \
	-cpu host \
	-m 2G \
	-smp 1 \
	-drive file=fedora-kvm.raw,format=raw,if=virtio \
	-bios /usr/share/OVMF/OVMF_CODE.fd \
	$SERIAL_CONSOLE

