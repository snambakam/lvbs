#!/bin/bash

set -euo pipefail

pushd $HOME/Downloads

qemu-img create \
	-f qcow2 \
	/home/snambakam/Downloads/data-10G.qcow2 \
	10G

popd
