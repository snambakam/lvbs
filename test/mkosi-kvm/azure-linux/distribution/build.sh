#!/bin/bash

mkosi \
	--initrd=../initrd/image.cpio.zst \
	--force \
	build
