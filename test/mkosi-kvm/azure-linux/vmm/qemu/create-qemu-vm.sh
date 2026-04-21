#!/bin/bash

pushd $HOME/Downloads

qemu-system-x86_64 \
  -enable-kvm \
  -cpu host \
  -m 2G \
  -smp 2 \
  -nographic \
  -drive file=/home/snambakam/Downloads/core-3.0.20260304.qcow2,format=qcow2,if=virtio \
  -drive file=data-10G.qcow2,format=qcow2,if=virtio \
  -cdrom /home/snambakam/Downloads/meta-user-data.iso \
  -boot order=c

popd
