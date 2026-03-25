#!/bin/bash

sudo virt-install \
	--name fedora-mkosi \
	--memory 2048 \
	--vcpus 1 \
	--disk path=/var/lib/libvirt/images/fedora-kvm.raw,format=raw,bus=virtio \
	--os-variant fedora43 \
	--boot uefi \
	--graphics none \
	--console pty,target_type=serial \
	--import

