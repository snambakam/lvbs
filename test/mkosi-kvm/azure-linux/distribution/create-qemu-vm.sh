#!/bin/bash

qemu-system-x86_64 \
  -enable-kvm \
  -m 4096 \
  -bios /usr/share/OVMF/OVMF_CODE.fd \
  -drive file=image.raw,format=raw \
  -display none -serial mon:stdio \
  -object rng-random,filename=/dev/urandom,id=rng0 \
  -device virtio-rng-pci,rng=rng0
