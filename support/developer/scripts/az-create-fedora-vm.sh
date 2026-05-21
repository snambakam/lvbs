#!/bin/bash

GALLERY="Fedora-5e266ba4-2250-406d-adad-5d73860d958f"

LOCATION=westus2
SIZE_ARM64=
# Note: No ARM64 VM Sizes in Azure support accelerated nested virtualization with KVM
SIZE_X86_64=Standard_D4ads_v5 # AMD based VM size for testing
#SIZE_X86_64=D4s_v5 # Intel based VM size for testing
IMAGE_NAME=
VERSION=
SIZE=
SSH_KEY_PATH=
USERNAME=`whoami`
RESOURCE_GROUP=$USERNAME-dev-test
TAGS="owner=$USERNAME"
ARCH=

function showUsage() {
  echo "Usage: az-create-fedora-vm.sh <options>"
  echo "  -a <arch>: Architecture"
  echo "             arch: { x64, arm64}"
  echo "  -n <instance name>"
  echo "  -i <image name>: Image name in the Fedora community gallery"
  echo "  -v <version>: Image version"
  echo "  -k <path to ssh public key>"
  echo "  -l <location>: Azure Location"
  echo "  -r <resource group>: Azure Resource Group to place VM"
  echo "  -s <vm size>: Azure VM Size"
  echo "  -h: show this help message"
}

optstring="a:i:k:n:l:hr:s:v:"

while getopts ${optstring} arg; do
  case ${arg} in
    h) showUsage; exit 0 ;;
    a) case $OPTARG in
         x64)   ARCH=x86_64 ;;
         arm64) ARCH=arm64 ;;
         *) echo "Invalid architecture: $OPTARG"; showUsage; exit 2 ;;
       esac ;;
    n) INSTANCE_NAME=$OPTARG ;;
    i) IMAGE_NAME=$OPTARG ;;
    v) VERSION=$OPTARG ;;
    k) SSH_KEY_PATH=$OPTARG ;;
    l) LOCATION=$OPTARG ;;
    r) RESOURCE_GROUP=$OPTARG ;;
    s) SIZE=$OPTARG ;;
    :) echo "$0: Must supply an argument to -$OPTARG." >&2; exit 1 ;;
    ?) echo "Invalid option: -${OPTARG}."; exit 2 ;;
  esac
done

if [ -z "$RESOURCE_GROUP" ]; then
  echo "Error: Invalid resource group specified - [$RESOURCE_GROUP]"
  showUsage
  exit 1
fi

if [ -z "$LOCATION" ]; then
  echo "Error: Invalid location specified - [$LOCATION]"
  showUsage
  exit 1
fi

if [ -z "$SIZE" ]; then
  case $ARCH in
    x86_64)
      SIZE=$SIZE_X86_64 ;;
    arm64)
      SIZE=$SIZE_ARM64 ;;
    *)
      echo "Error: Invalid architecture specified - [$ARCH]"
      showUsage
      exit 2 ;;
  esac
fi

[ -z "$SSH_KEY_PATH" ] && SSH_KEY_PATH="~/.ssh/id_rsa_azure.pub"

if [ -z "$IMAGE_NAME" ]; then
  echo "Error: Image name not specified"
  showUsage
  exit 4
fi

if [ -z "$VERSION" ]; then
  echo "Error: Image version not specified"
  showUsage
  exit 4
fi

if [ -z "$INSTANCE_NAME" ]; then
  echo "Error: Invalid instance name specified - [$INSTANCE_NAME]"
  showUsage
  exit 3
fi

IMAGE_REF="/CommunityGalleries/${GALLERY}/Images/${IMAGE_NAME}/Versions/${VERSION}"

az vm create \
  --resource-group $RESOURCE_GROUP \
  --name $INSTANCE_NAME \
  --image $IMAGE_REF \
  --os-disk-size-gb 60 \
  --size $SIZE \
  --public-ip-sku Standard \
  --admin-username $USERNAME \
  --assign-identity [system] \
  --ssh-key-values "$SSH_KEY_PATH" \
  --tags $TAGS \
  --location $LOCATION
