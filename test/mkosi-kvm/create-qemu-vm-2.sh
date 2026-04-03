#!/bin/bash

CONSOLE="-nographic"
BIOS="/usr/share/OVMF/OVMF_CODE_4M.fd"
SERIAL_CONSOLE="-serial mon:stdio"
qemu-system-x86_64 \
	-enable-kvm \
	-machine q35 \
	-cpu host \
	-m 2G \
	-smp 1 \
	-drive file=fedora-kvm.raw,format=raw,if=virtio \
	-drive if=pflash,format=raw,readonly=on,file=$BIOS \
	-drive if=pflash,format=raw,file=OVMF_VARS_4M.fd \
	$SERIAL_CONSOLE
