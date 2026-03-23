#!/bin/bash

IS_NESTED=N
NESTED_FILE=
if [ -d /sys/module/kvm_intel ]; then
    NESTED_FILE=/sys/module/kvm_intel/parameters/nested
elif [ -d /sys/module/kvm_amd ]; then
    NESTED_FILE=/sys/module/kvm_amd/parameters/nested
fi
if [ ! -z $NESTED_FILE ]; then
	IS_NESTED=$(cat "$NESTED_FILE")
fi
echo $IS_NESTED
