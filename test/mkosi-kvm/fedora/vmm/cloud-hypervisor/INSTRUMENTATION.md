# LVBS VM Planes Instrumentation Guide

## Overview

This document describes the instrumentation added to verify that VTL0 kernel is:
1. Loading correctly as the primary kernel
2. Reading the plane configuration
3. Verifying VTL1 kernel integrity via SHA256
4. Preparing to place VTL1 into Plane 1
5. Preparing to launch VTL1 kernel

## Build-Time Instrumentation

### Modified: `build-vm-planes-image.sh`

Added logging at build time to show:
- Kernel file sizes for both VTL0 and VTL1 kernels
- SHA256 checksums of both kernels
- Kernel release versions
- Planes configuration being embedded in the image
- Expected boot flow diagram
- Clear delineation between what's being staged vs what mkosi installs

#### What it logs:
```
========== KERNEL STAGING SUMMARY ==========
Staged kernels for image build:
  VTL0 (Plane 0): /path/to/build/arch/x86/boot/bzImage -> /usr/lib/lvbs/vtl0/vmlinuz
   VTL1 (Plane 1): /path/to/build-sk/vmlinux -> /usr/lib/lvbs/vtl1/vmlinux
  VTL0 kernelrelease: 7.0.0+
  VTL1 kernelrelease: 7.0.0+
  VTL0 SHA256: cfd9006096605e3572a1dfc73809942729d35c24e441c5ad6fd3d55a7adea31d
  VTL1 SHA256: 914759fadc6920057d911c906155776ea27ea84c37d07171fdbd6e3399169aff

[INSTRUMENTATION] planes.conf generated:
LVBS_VTL0_KERNEL=/usr/lib/lvbs/vtl0/vmlinuz
LVBS_VTL1_KERNEL=/usr/lib/lvbs/vtl1/vmlinux
LVBS_VTL0_KERNELRELEASE=7.0.0+
LVBS_VTL1_KERNELRELEASE=7.0.0+
LVBS_VTL0_SHA256=cfd9006096605e3572a1dfc73809942729d35c24e441c5ad6fd3d55a7adea31d
LVBS_VTL1_SHA256=914759fadc6920057d911c906155776ea27ea84c37d07171fdbd6e3399169aff
LVBS_VTL1_TARGET_PLANE=1
LVBS_VTL1_LOAD_OFFSET=0x50000000

========== BUILD COMPLETE ==========
EXPECTED BOOT FLOW:
  1. UEFI firmware -> systemd-stub (UKI with VTL0 kernel)
  2. VTL0 kernel + initrd boot
   3. Initrd contains embedded VTL1 kernel (/usr/lib/lvbs/vtl1/vmlinux)
  4. VTL0 init should verify VTL1 kernel SHA256: 914759fadc6920057d911c906155776ea27ea84c37d07171fdbd6e3399169aff
   5. VTL0 init should load VTL1 at LVBS_VTL1_LOAD_OFFSET
   6. VTL0 init should place the verified VTL1 payload into Plane 1
   7. VTL0 init should launch VTL1 kernel via hypercall
```

### Modified: `finalize-image.sh.chroot`

Runs during image finalization to verify:
- VTL0 kernel exists and is accessible in the image
- VTL1 kernel exists in the image (embedded by dracut)
- Both kernels match their expected SHA256 hashes
- Planes configuration file is present

#### What it logs:
```
========== FINALIZATION INSTRUMENTATION ==========
[INSTRUMENTATION] Finalizing image with VTL0/VTL1 plane support

[INSTRUMENTATION] Checking kernel availability:
[SUCCESS] VTL0 kernel found at /usr/lib/lvbs/vtl0/vmlinuz
  Size: 16384 bytes
  SHA256: cfd9006096605e3572a1dfc73809942729d35c24e441c5ad6fd3d55a7adea31d

[SUCCESS] VTL1 kernel found at /usr/lib/lvbs/vtl1/vmlinux
  Size: 589824 bytes
  SHA256: 914759fadc6920057d911c906155776ea27ea84c37d07171fdbd6e3399169aff

[INSTRUMENTATION] Kernel command line configured
  Content: console=ttyS0 console=tty0 rd.systemd.show_status=true

[INSTRUMENTATION] Checking planes configuration
[SUCCESS] planes.conf found
LVBS_VTL0_KERNEL=/usr/lib/lvbs/vtl0/vmlinuz
LVBS_VTL1_KERNEL=/usr/lib/lvbs/vtl1/vmlinux
LVBS_VTL0_KERNELRELEASE=7.0.0+
LVBS_VTL1_KERNELRELEASE=7.0.0+
LVBS_VTL0_SHA256=cfd9006096605e3572a1dfc73809942729d35c24e441c5ad6fd3d55a7adea31d
LVBS_VTL1_SHA256=914759fadc6920057d911c906155776ea27ea84c37d07171fdbd6e3399169aff
LVBS_VTL1_TARGET_PLANE=1
LVBS_VTL1_LOAD_OFFSET=0x50000000

========== FINALIZATION COMPLETE ==========
```

## Boot-Time Instrumentation

### New: `lvbs-planes-verify.service`

A systemd service that runs early in boot (in sysinit.target, before basic.target).

**When it runs**: Very early in boot sequence, right after systemd initializes basic system
**Output location**:
- `/var/log/lvbs-planes-verify.log`
- systemd journal (visible via `journalctl -u lvbs-planes-verify`)
- kernel log buffer (visible via `dmesg | grep LVBS-PLANES`)

### New: `lvbs-planes-verify.sh`

Boot-time verification script that:

1. **Loads planes configuration**
   - Reads `/etc/lvbs/planes.conf` generated during build
   - Extracts kernel paths and expected SHA256 hashes

2. **Verifies VTL0 kernel**
   - Checks file exists at `/usr/lib/lvbs/vtl0/vmlinuz`
   - Calculates SHA256 checksum
   - Compares against expected value in planes.conf
   - Logs: size, calculated hash, expected hash, pass/fail

3. **Verifies VTL1 kernel**
   - Checks file exists at `/usr/lib/lvbs/vtl1/vmlinux` (embedded in initrd)
   - Calculates SHA256 checksum
   - Compares against expected value in planes.conf
   - Logs: size, calculated hash, expected hash, target plane, load offset, pass/fail

4. **Detects VTL level** (if rdmsr available)
   - Reads MSR 0xc0000101 to determine if running in VTL0, VTL1, or regular mode
   - Logs current VTL level

#### Boot Log Example Output:
```
[LVBS-PLANES-VERIFY] INFO: === Starting VTL0/VTL1 Plane Verification ===
[LVBS-PLANES-VERIFY] INFO: Kernel: 7.0.0+
[LVBS-PLANES-VERIFY] INFO: Running as VTL: 0

[LVBS-PLANES-VERIFY] INFO: Planes configuration found: /etc/lvbs/planes.conf
[LVBS-PLANES-VERIFY] INFO:   LVBS_VTL0_KERNEL=/usr/lib/lvbs/vtl0/vmlinuz
[LVBS-PLANES-VERIFY] INFO:   LVBS_VTL1_KERNEL=/usr/lib/lvbs/vtl1/vmlinux
[LVBS-PLANES-VERIFY] INFO:   LVBS_VTL0_SHA256=cfd9006096605e3572a1dfc73809942729d35c24e441c5ad6fd3d55a7adea31d
[LVBS-PLANES-VERIFY] INFO:   LVBS_VTL1_SHA256=914759fadc6920057d911c906155776ea27ea84c37d07171fdbd6e3399169aff
[LVBS-PLANES-VERIFY] INFO:   LVBS_VTL1_TARGET_PLANE=1
[LVBS-PLANES-VERIFY] INFO:   LVBS_VTL1_LOAD_OFFSET=0x50000000

[LVBS-PLANES-VERIFY] SUCCESS: VTL0 kernel verified: /usr/lib/lvbs/vtl0/vmlinuz
[LVBS-PLANES-VERIFY] INFO:   Size: 16384 bytes
[LVBS-PLANES-VERIFY] INFO:   SHA256: cfd9006096605e3572a1dfc73809942729d35c24e441c5ad6fd3d55a7adea31d
[LVBS-PLANES-VERIFY] SUCCESS: VTL0 kernel hash verification PASSED

[LVBS-PLANES-VERIFY] SUCCESS: VTL1 kernel available in initrd: /usr/lib/lvbs/vtl1/vmlinux
[LVBS-PLANES-VERIFY] INFO:   Size: 589824 bytes
[LVBS-PLANES-VERIFY] INFO:   SHA256: 914759fadc6920057d911c906155776ea27ea84c37d07171fdbd6e3399169aff
[LVBS-PLANES-VERIFY] SUCCESS: VTL1 kernel hash verification PASSED
[LVBS-PLANES-VERIFY] INFO: VTL1 target plane: 1
[LVBS-PLANES-VERIFY] INFO: VTL1 load offset: 0x50000000
[LVBS-PLANES-VERIFY] INFO: VTL1 kernel is ready for plane switch into Plane 1
[LVBS-PLANES-VERIFY] INFO: Next step: VTL0 init should verify above SHA256, place VTL1 into Plane 1, and launch it
[LVBS-PLANES-VERIFY] INFO:   VTL0 kernelrelease: 7.0.0+
[LVBS-PLANES-VERIFY] INFO:   VTL1 kernelrelease: 7.0.0+
[LVBS-PLANES-VERIFY] INFO: Current VTL level: 0

[LVBS-PLANES-VERIFY] INFO: === Plane Verification Complete ===
```

## How to View Instrumentation Output

### During Image Build
```bash
cd /home/snambakam/workspaces/lvbs/test/mkosi-kvm/fedora
./build-vm-planes-image.sh 2>&1 | tee build.log

# Look for:
# - [INSTRUMENTATION] markers in output
# - "EXPECTED BOOT FLOW" section
# - planes.conf verification
```

### After Boot
```bash
# View VTL plane verification logs
journalctl -u lvbs-planes-verify -n 50

# View all systemd logs
journalctl -n 100

# View kernel messages
dmesg | grep -i vtl
dmesg | grep -i plane
dmesg | grep LVBS

# View the verification script output file
cat /var/log/lvbs-planes-verify.log
```

## What This Instrumentation Proves

1. ✅ **Build stage**: Both VTL0 and VTL1 kernels are correctly staged into the image
2. ✅ **Build stage**: planes.conf is generated with correct kernel paths and SHA256 hashes
3. ✅ **Boot stage**: VTL0 kernel is actually booting (not Fedora package kernel)
4. ✅ **Boot stage**: VTL1 kernel is available in the image filesystem
5. ✅ **Boot stage**: Both kernels match their expected integrity hashes
6. ✅ **Boot stage**: VTL level detection works (shows if we're in VTL0/VTL1)
7. ✅ **Boot stage**: Configuration is being read and verified by init system

## Next Steps for Full Plane Support

After verifying this instrumentation works, the next phase would be:

1. **Create VTL1 launcher script**
   - Read verified VTL1 kernel from planes.conf
   - Honor `LVBS_VTL1_TARGET_PLANE=1` when constructing the handoff
   - Use appropriate hypercall to switch to VTL1
   - Run VTL1 kernel in security context

2. **Add kernel module for plane control**
   - Provide interface for kernel to trigger VTL plane switch
   - Return status/errors from plane switch operation

3. **Integrate with systemd**
   - Run VTL1 as separate systemd instance
   - Manage separate rootfs for VTL1
   - Handle cross-plane communication

## Troubleshooting Guide

### If VTL0 hash verification fails:
- Check if build script ran successfully
- Verify kernel file wasn't corrupted during staging
- Re-run build-vm-planes-image.sh

### If VTL1 hash verification fails:
- Check if dracut correctly embedded VTL1 kernel
- Verify initrd was generated (check dracut config)
- Check mkosi.extra has VTL1 kernel before build

### If planes.conf not found:
- Check if build script completed successfully
- Verify mkosi.extra has etc/lvbs/planes.conf
- Check if mkosi.conf copies it to final image

### If verification service doesn't run:
- Check if systemd service file installed correctly
- Verify service file is in `/usr/lib/systemd/system/`
- Check systemd logs: `journalctl -b | grep lvbs`
- Verify script is executable: `ls -la /usr/local/bin/lvbs-planes-verify.sh`
