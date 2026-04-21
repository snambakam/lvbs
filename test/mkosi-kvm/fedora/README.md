# VM Plane orchestration

## Introduction

The VM boot sequence will include secure-boot through a UKI (Unified Kernel Image).

The UKI will contain the following artifacts:

1. UEFI boot stub (systemd-boot)
2. Kernel Image for Plane 0
3. Kernel Image for Plane 1
4. Intramfs
    1. Kernel command line for Plane 0
    2. Kernel command line for Plane 1
    3. Boot loader for Kernel in Plane 1
    4. Plane configuration (planes.json)

## Build Folder Manifest

1. image -- where the VM image is composed
2. vmm/cloud-hypervisor -- orchestration through cloud-hypervisor
3. vmm/qemu -- orchestration through qemu

