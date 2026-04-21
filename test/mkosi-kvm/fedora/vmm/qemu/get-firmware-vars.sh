#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE_DIR="$SCRIPT_DIR/../image"

VARS_FILE=OVMF_VARS_4M.fd

cp -f /usr/share/OVMF/$VARS_FILE "$IMAGE_DIR/"
chmod u+w "$IMAGE_DIR/$VARS_FILE"
