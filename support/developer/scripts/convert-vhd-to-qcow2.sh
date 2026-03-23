#!/bin/bash

if [ $# -lt 1 ]; then
    echo "Usage: $0 <path to vhd>"
    exit 1
fi

SRC_IMAGE=$1
TARGET_IMAGE="${SRC_IMAGE%.vhd}.qcow2"

qemu-img convert -O qcow2 "$SRC_IMAGE" "$TARGET_IMAGE"
