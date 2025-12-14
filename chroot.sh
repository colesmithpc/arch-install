#!/usr/bin/env bash
set -euo pipefail

# Time-zone
ln -sf /usr/share/zoneinfo/US/Central /etc/localtime
hwclock --systohc

# Locales
sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

# Hostname
echo archlinux > /etc/hostname
cat <<EOF > /etc/hosts
127.0.0.1	localhost
::1         localhost
127.0.1.1   archlinux.localdomain archlinux
EOF

# User creation, root password
passwd

useradd -m -G wheel cole
passwd cole
sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

# Systemd bootloader install & configuration
bootctl install

cat <<EOF > /boot/loader/loader.conf
default arch
timeout 3
editor no
EOF

cat <<EOF > /boot/loader/entries/arch.conf
title Arch Linux
linux /vmlinuz-linux
initrd /intel-ucode.img
initrd /initramfs-linux.img
options root=PARTUUID=$(blkid -s PARTUUID -o value /dev/nvme0n1p2) rw nvidia-drm.modeset=1
EOF

set -i 's/MODULES=()/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' /etc/mkinitcpio.conf

mkinitcpio -P

systemctl enable NetworkManager
systemctl enable sddm
systemctl enable bluetooth
systemctl enable thermald
systemctl enable avahi-daemon


