#!/bin/bash

cloud-hypervisor \
    --kernel fedora-kvm.vmlinuz \
    --initramfs fedora-kvm.initrd \
    --cmdline "root=/dev/vda2 console=ttyS0" \
    --disk path=fedora-kvm.raw \
    --cpus boot=2 \
    --memory size=1G

