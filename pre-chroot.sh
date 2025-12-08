#!/usr/bin/env bash

# Cole's arch install script (pre-chroot)

set -e

# Set keyboard
loadkeys us
localectl status

# Wipe disk and create partitions
sgdisk --zap-all /dev/nvme0n1

# EFI (550M), Swap (8G or change size here), Root (rest)
sgdisk -n 1:0:+550M -t 1:ef00 -c 1:"EFI System Partition" /dev/nvme0n1
sgdisk -n 2:0:+8G   -t 2:8200 -c 2:"Swap" /dev/nvme0n1
sgdisk -n 3:0:0     -t 3:8304 -c 3:"Linux Root" /dev/nvme0n1

# Format partitions
mkfs.fat -F32 /dev/nvme0n1p1
mkswap /dev/nvme0n1p2
mkfs.ext4 -F /dev/nvme0n1p3

# Mount partitions
mount /dev/nvme0n1p3 /mnt
mkdir -p /mnt/boot/efi
mount /dev/nvme0n1p1 /mnt/boot/efi
swapon /dev/nvme0n1p2

# Base system + firmware + intel microcode + NVidia + networking stack + SSD utilities
pacstrap -K /mnt \
    base linux linux-firmware linux-headers intel-ucode \
    networkmanager iwd \
    nvidia nvidia-utils nvidia-settings \
    nvme-cli smartmontools bluez bluez-utils \
    base-devel reflector

# Generate fstab
genfstab -U /mnt >> /mnt/etc/fstab

# Enter chroot
arch-chroot /mnt
