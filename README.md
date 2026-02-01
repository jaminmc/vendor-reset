# Vendor Reset

The goal of this project is to provide a kernel module that is capable of
resetting hardware devices into a state where they can be re-initialized or
passed through into a virtual machine (VFIO). While it would be great to have
these in the kernel as PCI quirks, some of the reset procedures are very complex
and would never be accepted as a quirk (ie AMD Vega 10).

By providing this as an out of tree kernel module, vendors will be able to
easily create pull requests to add functionality to this module, and users will
be able to easily update this module without requiring a complete kernel rebuild.

## Patching the kernel

TL;DR - No patching required.

This module has been written to use `ftrace` to hook `pci_dev_specific_reset`,
allowing it to handle device resets directly without patching the running
kernel. Simply modprobing the module is enough to enable the reset routines for
all supported hardware.

## Requirements

Ensure your kernel has the following options enabled:

```
CONFIG_FTRACE=y
CONFIG_KPROBES=y
CONFIG_PCI_QUIRKS=y
CONFIG_KALLSYMS=y
CONFIG_KALLSYMS_ALL=y
CONFIG_FUNCTION_TRACER=y
```

## Installing

This module can be installed either using the standard `make`, `make install`
pattern, or through `dkms` (recommended).

    dkms install .

Put `udev/99-vendor-reset.rules` into `/etc/udev/rules.d/99-vendor-reset.rules`

    udevadm control --reload-rules && udevadm trigger

## Usage

Either `modprobe vendor-reset` or add the device to the appropriate place to
load it at system boot, such as `/etc/modules` (Debian). Consult your
distribution's documentation as to the best way to perform this.

**NOTE: ** This module must be loaded EARLY, the default reset the kernel will
try to perform completely breaks the GPU which this module can not recover from.
Please consult your distributions documentation on how to do this, for most
however it will be as simple as adding `vendor-reset` to `/etc/modules` and
updating your initrd.

Then execute: `echo device_specific > /sys/bus/pci/devices/[REPLACE_WITH_GPU_ID]/reset_method.`

Both of these things are also accomplished by `99-vendor-reset.rules`.

If successful, vendor-reset will output to dmesg and prevent the reset bug:

```
[  802.217359] vfio-pci 0000:03:00.0: AMD_NAVI32: version 1.1
[  802.217361] vfio-pci 0000:03:00.0: AMD_NAVI32: performing pre-reset
[  802.217457] vfio-pci 0000:03:00.0: AMD_NAVI32: performing reset
[  802.240518] ATOM BIOS: 115-D712BP2-100
[  802.240520] vendor-reset-drm: atomfirmware: bios_scratch_reg_offset initialized to 4c
[  802.240523] vfio-pci 0000:03:00.0: AMD_NAVI32: bus reset disabled? yes
[  802.240527] vfio-pci 0000:03:00.0: AMD_NAVI32: SMU response reg: 1, sol reg: 195b6400, mp1 intr enabled? yes, bl ready? no
[  802.240529] vfio-pci 0000:03:00.0: AMD_NAVI32: Clearing scratch regs 6 and 7
[  802.241314] vfio-pci 0000:03:00.0: AMD_NAVI32: begin psp mode 1 reset
[  802.745298] vfio-pci 0000:03:00.0: AMD_NAVI32: mode1 reset succeeded
[  802.745367] vfio-pci 0000:03:00.0: AMD_NAVI32: PSP mode1 reset successful
[  802.745374] vfio-pci 0000:03:00.0: AMD_NAVI32: performing post-reset
[  802.770050] vfio-pci 0000:03:00.0: AMD_NAVI32: reset result = 0
```

## Supported Devices

| Vendor | Family     | Common Name(s)             |
|--------|------------|----------------------------|
| AMD    | Polaris 10 | RX 470, 480, 570, 580, 590 | 
| AMD    | Polaris 11 | RX 460, 560                |
| AMD    | Polaris 12 | RX 540, 550                |
| AMD    | Vega 10    | Vega 56/64/FE              |
| AMD    | Vega 20    | Radeon VII                 |
| AMD    | Vega 20    | Instinct MI100             |
| AMD    | Navi 10    | 5600XT, 5700, 5700XT       |
| AMD    | Navi 12    | Pro 5600M                  |
| AMD    | Navi 14    | Pro 5300, RX 5300, 5500XT  |
| AMD    | Navi 32    | RX 7800 XT                 |

## Developing

If you are a vendor intending to add support for your device to this project
please first consider two things:

1. Can you fix your hardware/firmware to reset correctly using FLR or a BUS
   reset?
2. Is the reset simple enough that it should really be a kernel pci quirk
   (see: kernel/drivers/pci/quirk.c)?

If you answer yes to either of these questions this project is not for you.

## Additional resources

- [Linux Kernel documentation - AMDGPU Hardware List](https://docs.kernel.org/gpu/amdgpu/amd-hardware-list-info.html)
- [AMD GPUopen - GPU architecture programming documentation](https://gpuopen.com/amd-gpu-architecture-programming-documentation/)
