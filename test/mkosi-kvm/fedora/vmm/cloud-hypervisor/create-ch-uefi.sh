#!/bin/bash

cloud-hypervisor \
    --kernel /path/to/CLOUDHV_EFI.bin \
    --disk path=fedora-kvm.raw \
    --cpus boot=2 \
    --memory size=1G \
    --net tap=,mac=,ip=,mask=
