#!/usr/bin/env bash

# Usage:
#   ./find_nested_virt_skus.sh eastus
#   ./find_nested_virt_skus.sh westus2

set -euo pipefail

LOCATION="${1:-eastus}"

echo "Finding VM sizes in region: $LOCATION"
echo "Filtering for families that are known to support nested virtualization..."
echo

# Known families (heuristic filter)
FAMILY_REGEX='Standard_(D|E|F).*v(3|4|5|6)'

az vm list-skus \
    --location "$LOCATION" \
    --resource-type virtualMachines \
    --query "[?contains(name, 'Standard_')].{Name:name, Family:family, CPU:capabilities[?name=='vCPUs'] | [0].value}" \
    -o json | jq -r \
    --arg regex "$FAMILY_REGEX" '
    .[]
    | select(.Name | test($regex))
    | "\(.Name)\tFamily=\(.Family)\tvCPUs=\(.CPU)"
    ' | sort
