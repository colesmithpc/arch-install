#!/bin/bash
# Automated arch installation script, change parameters to your liking

set -e

DISK="/dev/nvme1n1"
HOSTNAME="precision"
USERNAME="cole"
PASSWORD="coleman2002"
SWAP_SIZE="8G"

echo "Partitioning $DISK..."
sgdisk -Z $DISK
sgdisk -n1:0:+512M -t1:ef00 -c1:"EFI System" $DISK
sgdisk -n2:0:0 -t2:8300 -c2:"Linux Root" $DISK

echo "Formatting partitions..."
mkfs.fat -F32 "${DISK}p1"	# EFI
mkfs.ext4 "${DISK}p2"		# root

echo "Mounting partitions..."
mount "${DISK}p2" /mnt
mkdir -p /mnt/boot
mount "${DISK}p1" /mnt/boot

echo "Installing base system and KDE..."
pacstrap /mnt base linux linux-firmware sudo vim nano networkmanager \
	xorg xorg-xinit xorg-xinput plasma kde-applications sddm ttf-dejavu ttf-liberation \
	plasma-nm kde-gtk-config kde-config-gtk-style ttf-ubuntu-font-family

echo "Generating fstab..."
genfstab -U /mnt >> /mnt/etc/fstab

arch-chroot /mnt /bin/bash <<EOF
ln -sf /usr/share/zoneinfo/US/Central /etc/localtime
hwclock --systohc

echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

echo "$HOSTNAME" > /etc/hostname
echo "127.0.0.1		localhost" >> /etc/hosts
echo "::1		localhost" >> /etc/hosts
echo "127.0.1.1		$HOSTNAME.localdomain $HOSTNAME" >> /etc/hosts

echo "root:$PASSWORD" | chpasswd

useradd -m -G wheel -s /bin/bash $USERNAME
echo "$USERNAME:$PASSWORD" | chpasswd
echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers

bootctl install
cat <<BOOT > /boot/loader/loader.conf
default arch
timeout 3
editor 0
BOOT

cat <<ARCH > /boot/loader/entries/arch.conf
title Arch Linux
linux /vmlinuz-linux
initrd /initramfs-linux.img
options root=PARTUUID=$(blkid -s PARTUUID ${DISK}p2) rw
ARCH

systemctl enable NetworkManager
systemctl enable sddm
systemctl enable bluetooth
systemctl enable cups
EOF

echo "Unmounting partitions..."
umount -R /mnt
echo "Installation complete! Reboot now."
