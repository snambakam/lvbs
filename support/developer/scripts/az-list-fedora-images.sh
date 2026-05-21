#!/usr/bin/env bash

set -euo pipefail

LOCATION="${1:-eastus}"
GALLERY="Fedora-5e266ba4-2250-406d-adad-5d73860d958f"

SUBSCRIPTION_ID=$(az account show --query id -o tsv)

if [[ -z "$SUBSCRIPTION_ID" ]]; then
    echo "Failed to determine subscription ID"
    exit 1
fi

BASE_URL="https://management.azure.com/subscriptions/${SUBSCRIPTION_ID}/providers/Microsoft.Compute/locations/${LOCATION}/communityGalleries/${GALLERY}"

echo "Listing Fedora images from community gallery in ${LOCATION}"
echo

# Get image definitions
IMAGES_JSON=$(az rest \
    --method get \
    --url "${BASE_URL}/images?api-version=2022-03-03")

IMAGE_NAMES=$(echo "$IMAGES_JSON" | jq -r '.value[].name')

if [[ -z "$IMAGE_NAMES" ]]; then
    echo "No images found"
    exit 1
fi

for IMAGE in $IMAGE_NAMES; do
    echo "Image: $IMAGE"

    # Get versions for each image
    VERSIONS_JSON=$(az rest \
        --method get \
        --url "${BASE_URL}/images/${IMAGE}/versions?api-version=2022-03-03")

    echo "$VERSIONS_JSON" | jq -r '
        .value[]
        | "  Version: " + .name
    '

    echo
done