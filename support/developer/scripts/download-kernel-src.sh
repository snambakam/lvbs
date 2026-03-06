#!/bin/bash

set -euo pipefail

DOWNLOAD_DIR=$HOME/Downloads
WORKSPACE_HOME=$HOME/workspaces
WORKSPACE_DIR=

cleanup() {
    if [[ -n "${WORKSPACE_DIR}" && -d "${WORKSPACE_DIR}.tmp" ]]; then
        rm -rf "${WORKSPACE_DIR}.tmp"
    fi
}

#
# Main
#

trap cleanup SIGINT

if [ $# -lt 1 ]; then
    echo "Usage: $0 <version>"
    exit 1
fi

VERSION=$1
MAJOR="${VERSION%%.*}"
WORKSPACE_DIR=$WORKSPACE_HOME/linux-$VERSION

if [ -d "$WORKSPACE_DIR" ]; then
	echo "Error: Workspace exists - $WORKSPACE_DIR"
	exit 1
fi

curl -L \
	-o $DOWNLOAD_DIR/linux-$VERSION.tar.xz \
	https://cdn.kernel.org/pub/linux/kernel/v$MAJOR.x/linux-$VERSION.tar.xz


mkdir -p ${WORKSPACE_DIR}.tmp
tar \
	-xJf $DOWNLOAD_DIR/linux-$VERSION.tar.xz \
	-C ${WORKSPACE_DIR}.tmp \
	--strip-components=1
mv ${WORKSPACE_DIR}.tmp $WORKSPACE_DIR
