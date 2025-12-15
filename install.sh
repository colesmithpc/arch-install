#!/usr/bin/env bash

set -euo pipefail

# Simple arch installation script for my specific use case
# Please don't copy commands if you don't know what they do
# For example, my drives are read as nvme0n1, yours may differ

# Pre-flight
loadkeys us
timedatectl set-ntp true
ls /sys/firmware/efi/efivars

# Disk setup
wipefs -af /dev/nvme0n1
parted /dev/nvme0n1 --script mklabel gpt
parted /dev/nvme0n1 --script mkpart ESP fat32 1MiB 513MiB
parted /dev/nvme0n1 --script set 1 esp on
parted /dev/nvme0n1 --script mkpart primary ext4 513MiB 100%

mkfs.fat -F32 /dev/nvme0n1p1
mkfs.ext4 /dev/nvme0n1p2

# Mount 
mount /dev/nvme0n1p2 /mnt
mkdir /mnt/boot
mount /dev/nvme0n1p1 /mnt/boot

# Base system & must-haves
pacstrap /mnt \
  base linux linux-firmware linux-headers \
  sudo vim networkmanager \
  intel-ucode mesa \
  plasma plasma-desktop dolphin kate konsole sddm \
  nvidia nvidia-utils nvidia-settings \
  sof-firmware \
  pipewire pipewire-alsa pipewire-pulse wireplumber \
  bluez bluez-utils \
  thermald power-profiles-daemon irqbalance \
  util-linux e2fsprogs dosfstools ntfs-3g exfatprogs \
  noto-fonts noto-fonts-emoji ttf-dejavu ttf-liberation \
  networkmanager-openvpn openssh avahi nss-mdns \
  hwinfo pciutils usbutils dmidecode

# Fstab
genfstab -U /mnt >> /mnt/etc/fstab

# Chroot 
arch-chroot /mnt
