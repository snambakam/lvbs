#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE_DIR="$SCRIPT_DIR/../../image"

VARS_FILE=OVMF_VARS_4M.qcow2
SRC="/usr/share/edk2/ovmf/$VARS_FILE"
DST="$IMAGE_DIR/$VARS_FILE"

if [ ! -f "$SRC" ]; then
    echo "Error: $SRC not found" >&2
    exit 1
fi

# Copy only if local copy is missing or differs from the source
if [ ! -f "$DST" ] || ! cmp -s "$SRC" "$DST"; then
    cp -f "$SRC" "$DST"
    chmod u+w "$DST"
    echo "Updated $DST"
fi
