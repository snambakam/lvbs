#!/bin/bash

if [ $# -lt 1 ]; then
    echo "Usage: $0 <path to vhd>"
    exit 1
fi

SRC_IMAGE=$1
TARGET_IMAGE="${SRC_IMAGE%.vhd}.raw"

qemu-img convert -O raw "$SRC_IMAGE" "$TARGET_IMAGE"
