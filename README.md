# Arch Install Automation Scripts

This repository contains two scripts — **pre-chroot.sh** and **post-chroot.sh** — designed to fully automate my personal Arch Linux installation workflow. These scripts streamline system setup, enforce consistency across reinstalls, and reduce manual effort by performing everything from disk partitioning to base system setup and post-install configuration.

Both scripts are intended for **UEFI systems** and assume you understand the basics of installing Arch. They automate the tedious parts while keeping the workflow transparent and modifiable.

---

## 📁 Scripts Overview

### **pre-chroot.sh**
Runs **before** entering the chroot environment.  
Handles:
- Disk partitioning
- Filesystem creation
- Mounting
- Pacstrap base system install
- Generating fstab
- Preparing to enter chroot

### **post-chroot.sh**
Runs **inside** the chroot environment.  
Handles:
- Localization
- User creation
- Bootloader setup
- System configuration (hostname, timezone, services)
- Optional packages and customization

---

## 🚀 Goal of These Scripts

I created these scripts to streamline Arch installations by:
- Automating repetitive setup tasks  
- Maintaining consistent system configuration across machines  
- Speeding up pentesting VM deployments  
- Providing a fast, reproducible, minimal Arch environment  
- Supporting my scripting-focused workflow as an ethical hacker

These scripts are intentionally simple, transparent, and easily modifiable for your own workflow.

---

## 📦 How to Use

### 1. Clone the repo on your Arch ISO environment

```bash
git clone https://github.com/colesmithpc/arch-install.git
cd arch-install
```

### 2. Review the scripts (recommended)

```bash
vim pre-chroot.sh
vim post-chroot.sh
```

### 3. Make scripts executable

```bash
chmod +x pre-chroot.sh post-chroot.sh
```

### 4. Run the Pre-Chroot Script

```bash
./pre-chroot.sh
```

This script will:
- Partition your drive
- Format partitions
- Mount everything
- Install the base system
- Generate fstab
- Copy post-chroot.sh into `/mnt/root/`

When finished, you will be ready to enter the chroot environment.

### 5. Chroot Into the New System

```bash
arch-chroot /mnt
```

### 6. Run the Post-Chroot Script

Inside the chroot:

```bash
./post-chroot.sh
```

This script will finalize configuration:
- Set timezone and locale
- Configure hostname
- Create user + set passwords
- Install GRUB or systemd-boot (depending on your script version)
- Enable networking and other services

### 7. Reboot

```bash
exit
reboot
```

Remove installation media and boot into your new Arch system.

---

## ⚠️ Disclaimer

These scripts **will partition disks automatically**.  
Double-check device names before running.  
Modify the scripts to match your preferred layout if needed.

---

## 🤝 Contributions

If you want to improve the scripts, add flags, or modularize steps, PRs are welcome.

---

## 📜 License

MIT License — do whatever you'd like, just don’t blame me if your disk gets nuked.

