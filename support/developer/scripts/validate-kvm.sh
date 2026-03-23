#!/bin/bash

set -eou pipefail

#
# Main
#

grep -E -wo 'vmx|svm' /proc/cpuinfo

lsmod | grep kvm

if [ ! -c /dev/kvm ]; then
    echo "Error: KVM is not enabled"
fi

sudo virt-host-validate qemu
