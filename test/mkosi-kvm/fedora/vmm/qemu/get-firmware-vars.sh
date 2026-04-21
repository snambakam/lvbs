#!/bin/bash

VARS_FILE=OVMF_VARS_4M.fd

cp -f /usr/share/OVMF/$VARS_FILE .
chmod u+w $VARS_FILE
