#!/bin/bash

cloud-hypervisor \
    -v \
    --log-file /tmp/ch-debug.log \
    --kernel fedora-kvm.vmlinuz \
    --initramfs fedora-kvm.initrd \
    --cmdline "root=/dev/vda2 console=ttyS0 printk.caller=1" \
    --disk path=fedora-kvm.raw \
    --cpus boot=2 \
    --memory size=2G \
    --serial file=/tmp/plane-serial.log \
    --plane "plane_id=1,boot_vcpus=2,max_vcpus=2,kernel=fedora-kvm.vmlinuz,initramfs=fedora-kvm.initrd,cmdline=root=/dev/vda2 console=ttyS0 printk.caller=1"

