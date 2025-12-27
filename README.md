# Arch Linux Install Script (Personal Use)

A full single stage installation script for my personal workflow
This is tailored to my Dell Precision and my personal preferences, sway, kitty, etc

This repo exists for **learning, iteration, and reproducibility**, not as a one-size-fits-all installer.

---

## Overview

**`install.sh`**  
- Once cloned into the repo, simply run `./install.sh` to run the installation script
- Make sure to change these parameters:
- DISK, HOSTNAME, USERNAME, PASSWORD > Located at the top of the script.
---

## Target Setup

- **Boot mode:** UEFI
- **Filesystem:** GPT + FAT32 (EFI) + ext4 (root)
- **WM:** Sway
- **GPU:** NVIDIA (proprietary drivers)
- **Audio:** PipeWire
- **Networking:** Nmcli
- **Bootloader:** systemd-boot

> Disk names, packages, and assumptions are **hardware-specific**.

---

## ⚠️ Warning

**Do NOT blindly run this script.**

- Locale, timezone, hostname, and user are opinionated
- NVIDIA-specific configuration is included
- This will **destroy all data** on the target disk

Read and understand every command before use.

---

## Usage (Intentional, Not Automated)

1. Boot Arch ISO
2. Review and edit `install.sh` as needed
3. Run `install.sh`
4. `install.sh` runs all the needed commands, even in chroot
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
- This script can easily be modified to run a desktop environment like KDE or Gnome just by altering the pacstrap command, but you can do that inside the final install just as easily.
This repo will evolve as my Arch workflow evolves.
Expect breaking changes.
