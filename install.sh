#!/bin/bash
set -e

### BAREBONES ARCH LINUX PRE-CHROOT SETUP ###
### Minimal install: partition mount + base system ###

# --- 1. Verify Internet ---
ping -c1 archlinux.org >/dev/null 2>&1 || {
    echo "[!] No internet connection detected."
    exit 1
}

# --- 2. Sync system clock ---
timedatectl set-ntp true

# --- 3. Format partitions ---
echo "[*] Formatting partitions..."
mkfs.fat -F32 /dev/nvme0n1p1
mkswap /dev/nvme0n1p2
mkfs.ext4 -F /dev/nvme0n1p3

# --- 4. Mount ---
echo "[*] Mounting partitions..."
mount /dev/nvme0n1p3 /mnt
mount --mkdir /dev/nvme0n1p1 /mnt/boot
swapon /dev/nvme0n1p2

# --- 5. Pacstrap (minimal base only) ---
echo "[*] Installing base system..."
pacstrap -K /mnt base linux linux-firmware intel-ucode

# --- 6. Generate fstab ---
echo "[*] Generating fstab..."
genfstab -U /mnt >> /mnt/etc/fstab

# --- 7. Enter chroot ---
echo ""
echo "[*] Base system installed successfully!"
echo "[*] Run the following to chroot:"
echo "    arch-chroot /mnt"
