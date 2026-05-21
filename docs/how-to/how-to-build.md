# Building LVBS enabled Images

## Prerequisites

- Kernel source checked out at `$HOME/workspaces/linux` (or set `LINUX_SRC_ROOT`)
- Build tools: `gcc`, `make`, `objcopy`
- `mkosi` installed and in `PATH`
- `qemu-system-x86_64` with KVM support

## Steps

### 1. Build the kernel for Plane-0

Plane-0 runs the standard Linux kernel with VM Planes support enabled (VTL0).

```bash
cd test/kernel
./build.sh
```

Output: `test/kernel/build/arch/x86/boot/bzImage`

To install the kernel and modules system-wide:

```bash
./build.sh install
```

To clean the build directory:

```bash
./build.sh clean
```

### 2. Build the secure kernel for Plane-1

Plane-1 runs a minimal, stripped-down secure kernel (VTL1) with a statically-compiled init.

```bash
cd test/kernel
./build-sk.sh
```

Output: `test/kernel/build-sk/vmlinux`

### 3. Build the VM Image

Stages both kernels into a mkosi extra directory, prunes modules, and produces a bootable Fedora raw disk image with a UKI containing both plane kernels.

```bash
cd test/mkosi-kvm/fedora/image
./build-vm-planes-image.sh
```

Output: `test/mkosi-kvm/fedora/image/fedora-kvm.raw`

#### Environment variable overrides

| Variable | Default | Description |
|---|---|---|
| `LINUX_SRC_ROOT` | `$HOME/workspaces/linux` | Linux kernel source root |
| `VTL0_BUILD_DIR` | `../../../kernel/build` | Plane-0 build directory |
| `VTL1_BUILD_DIR` | `../../../kernel/build-sk` | Plane-1 build directory |
| `VTL1_MEMORY_SIZE` | `0x60000000` (1.5 GB) | Memory allocated to Plane 1 |
| `VTL1_VCPU_COUNT` | `1` | vCPUs allocated to Plane 1 |

### 4. Deploy the Image using QEMU

Launches the built image in QEMU with KVM acceleration and serial console attached to stdio.

```bash
cd test/mkosi-kvm/fedora/vmm/qemu
./create-qemu-vm-planes.sh
```

#### Options

| Flag | Default | Description |
|---|---|---|
| `--disk <path>` | `../../image/fedora-kvm.raw` | Disk image path |
| `--memory <size>` | `4G` | Guest memory |
| `--smp <count>` | `3` | Plane-0 vCPU count |
| `--bios <path>` | `/usr/share/edk2/ovmf/OVMF_CODE_4M.qcow2` | OVMF firmware |
| `--ovmf-vars <path>` | `../../image/OVMF_VARS_4M.qcow2` | OVMF variables file |
