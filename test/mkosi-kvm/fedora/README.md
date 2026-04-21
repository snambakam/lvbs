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

## Secure Boot sequence

1. Firmware (UEFI) verifies boot stub
2. Boot stub verifies UKI
3. Boot stub load Kernel 1 into Plane 0
4. Before launching the user space
    1. kexec into the (Secure) Kernel 2 into Plane 1
    2. Alternatively, use a small boot loader
5. Launch userspace associated with Plane 0 kernel

Notes:

1. All components within initramfs of UKI are validated.
2. Kernel 2 (in Plane 1) is launched before userspace is launched.

## Build Folder Manifest

1. image -- where the VM image is composed
2. vmm/cloud-hypervisor -- orchestration through cloud-hypervisor
3. vmm/qemu -- orchestration through qemu

