# Arch Linux Install Script (Personal Use)

A two-stage Arch Linux installation script tailored for my personal workflow and hardware.

This repo exists for **learning, iteration, and reproducibility**, not as a one-size-fits-all installer.

---

## Overview

The install process is intentionally split into **two scripts**:

1. **`install.sh`**  
   Runs on the Arch ISO (pre-chroot)
   - Disk partitioning & formatting
   - Mounting
   - `pacstrap` (base system, drivers, desktop)
   - `fstab` generation
   - Drops into chroot

2. **`chroot.sh`**  
   Runs *inside* the installed system
   - Timezone & locale
   - Hostname & hosts
   - User creation & sudo
   - Bootloader installation (systemd-boot)
   - Initramfs generation
   - Systemd service enablement

This separation keeps responsibilities clear and the scripts easy to reason about.

---

## Target Setup

- **Boot mode:** UEFI
- **Filesystem:** GPT + FAT32 (EFI) + ext4 (root)
- **Desktop:** KDE Plasma
- **Display Manager:** SDDM
- **GPU:** NVIDIA (proprietary drivers)
- **Audio:** PipeWire
- **Networking:** NetworkManager
- **Bootloader:** systemd-boot

> Disk names, packages, and assumptions are **hardware-specific**.

---

## ⚠️ Warning

**Do NOT blindly run this script.**

- Disk device names (`/dev/nvme0n1`) are hardcoded
- Locale, timezone, hostname, and user are opinionated
- NVIDIA-specific configuration is included
- This will **destroy all data** on the target disk

Read and understand every command before use.

---

## Usage (Intentional, Not Automated)

1. Boot Arch ISO
2. Review and edit `install.sh` as needed
3. Run `install.sh`
4. `install.sh` copies and executes `chroot.sh`
5. Reboot into the installed system

This is designed to be **transparent**, not fire-and-forget.

---

## Design Philosophy

- Do heavy work **before chroot**
- Do identity, boot, and permissions **inside chroot**
- Do user experience **after first boot**
- Prefer clarity over cleverness
- Fail loudly if something breaks

---

## License

No license.  
Use for reference, learning, or inspiration — not as a drop-in installer.

---

## Notes

This repo will evolve as my Arch workflow evolves.
Expect breaking changes.
