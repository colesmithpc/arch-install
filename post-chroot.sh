#!/usr/bin/env bash
# post_chroot_final.sh
# Run this inside the chroot after pacstrap/genfstab and before exit->umount->reboot
set -euo pipefail

# --- 0) Quick sanity: run as root inside chroot ---
if [ "$(id -u)" -ne 0 ]; then
  echo "Please run as root (inside the chroot)."
  exit 1
fi

# --- 1) Time, locale, hostname, vconsole ---
ln -sf /usr/share/zoneinfo/America/Chicago /etc/localtime
hwclock --systohc

sed -i 's/^#en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

echo "precision" > /etc/hostname

cat > /etc/hosts <<'EOF'
127.0.0.1	localhost
::1		localhost
127.0.1.1	precision.localdomain	precision
EOF

# Optional tty keymap
echo "KEYMAP=us" > /etc/vconsole.conf

# --- 2) Networking & Bluetooth (iwd backend for better power) ---
pacman -Syu --noconfirm networkmanager iwd bluez bluez-utils
mkdir -p /etc/NetworkManager/conf.d
cat > /etc/NetworkManager/conf.d/wifi_backend.conf <<'EOF'
[device]
wifi.backend=iwd
EOF

# reduce wifi power usage (NetworkManager side)
cat > /etc/NetworkManager/conf.d/wifi_powersave.conf <<'EOF'
[connection]
wifi.powersave=3
EOF

systemctl enable --now NetworkManager
systemctl enable --now bluetooth

# --- 3) Bootloader: systemd-boot with sane kernel params for power/perf ---
# Assumes /boot is mounted (p1), root is /dev/nvme0n1p3, swap is p2 (your layout)
bootctl --path=/boot install

# Kernel command line tuned for laptop (adjust if something misbehaves)
# i915.enable_psr=1 -> panel self refresh (saves power; disable if flicker)
# i915.enable_fbc=1 -> frame buffer compression
# nvme.noacpi=1 -> help on some NVMe controllers (Samsung). Remove if odd behavior
# Do NOT enable pcie_aspm=force here by default — it's risky; uncomment only if tested
KERNEL_OPTS="root=/dev/nvme0n1p3 rw loglevel=3 systemd.show_status=1 i915.enable_psr=1 i915.enable_fbc=1 nvme.noacpi=1"

cat > /boot/loader/entries/arch.conf <<EOF
title   Arch Linux (linux)
linux   /vmlinuz-linux
initrd  /intel-ucode.img
initrd  /initramfs-linux.img
options ${KERNEL_OPTS}
EOF

# update bootloader metadata
bootctl update

# --- 4) Core packages & utilities (drivers & power tools) ---
pacman -S --noconfirm \
    linux linux-headers intel-ucode \
    nvidia nvidia-utils nvidia-settings nvidia-dkms \
    nvme-cli smartmontools \
    tlp tlp-rdw powertop acpi acpi_call \
    zram-generator-defaults \
    reflector rsync \
    sudo base-devel

# Notes:
# - nvidia-dkms is included so the kernel and modules match across kernel updates; ok for your machine.
# - If you prefer the non-dkms nvidia package that's fine; dkms is safer across kernels.

# --- 5) TRIM, TLP, zram, and power services ---
systemctl enable --now fstrim.timer
systemctl enable --now tlp
# prefer dbus-broker (faster, lighter) when available
if command -v dbus-broker >/dev/null 2>&1; then
  systemctl enable --now dbus-broker.service || true
fi

# disable smartd on laptops to avoid periodic NVMe spin/wake (power savings)
systemctl disable --now smartd.service || true

# Enable zram (zram-generator-defaults provides sane defaults)
systemctl enable --now systemd-swap.service || true 2>/dev/null || true

# Reflector timer for mirror refreshing (optional)
if pacman -Qi reflector >/dev/null 2>&1; then
  systemctl enable --now reflector.timer || true
fi

# --- 6) mkinitcpio: ensure nvidia + intel modules included and regenerate ---
# Add needed modules to MODULES=(...) in /etc/mkinitcpio.conf if not present
# We'll ensure common ones are included: i915, intel_agp, nvme, nvidia modules
sed -i '/^MODULES=/d' /etc/mkinitcpio.conf
cat >> /etc/mkinitcpio.conf <<'EOF'
MODULES=(i915 nvme nvidia nvidia_modeset nvidia_uvm nvidia_drm)
EOF

# Keep HOOKS default but ensure 'resume' is not broken: we rely on zram so no special resume here
mkinitcpio -P

# --- 7) NVMe & SMART (quick config) ---
# don't enable smartd (disabled above). If you want monitoring, enable smartd manually.
# Do a quick NVMe check once
if command -v nvme >/dev/null 2>&1; then
  nvme id-ctrl /dev/nvme0n1 >/dev/null 2>&1 || true
fi

# --- 8) NVIDIA power management (realistic + safe) ---
# Use nvidia dynamic power management and enable nvidia DRM KMS for better PRIME behavior
cat > /etc/modprobe.d/nvidia.conf <<'EOF'
# Enable NVidia runtime power management and DRM modeset for PRIME
options nvidia NVreg_DynamicPowerManagement=0x02
options nvidia_drm modeset=1
EOF

# Make sure nvidia DRM module is loaded early for kms
cat > /etc/modules-load.d/nvidia.conf <<'EOF'
nvidia
nvidia_modeset
nvidia_uvm
nvidia_drm
EOF

# --- 9) PRIME Render Offload helpers (Wayland/X11 friendly) ---
# Xorg OutputClass to allow nvidia DRM and offload
mkdir -p /etc/X11/xorg.conf.d
cat > /etc/X11/xorg.conf.d/10-nvidia-drm-outputclass.conf <<'EOF'
Section "OutputClass"
    Identifier "nvidia"
    MatchDriver "nvidia-drm"
    Driver "nvidia"
    Option "AllowEmptyInitialConfiguration"
    ModulePath "/usr/lib/nvidia/xorg"
    ModulePath "/usr/lib/xorg/modules"
EndSection
EOF

# Create prime-run wrapper (if prime-run not available)
cat > /usr/local/bin/prime-run <<'EOF'
#!/usr/bin/env bash
# simple prime-run wrapper for render offload
__NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia __VK_LAYER_NV_optimus=NVIDIA_only "$@"
EOF
chmod +x /usr/local/bin/prime-run

# --- 10) Optional helper: safe nvidia unbind script (fallback, best-effort) ---
# This remains a best-effort helper but is NOT relied upon for power savings (use PRIME + modprobe opts above)
cat > /usr/local/bin/disable-nvidia.sh <<'EOF'
#!/usr/bin/env bash
# best-effort: unbind NVIDIA devices
for d in /sys/bus/pci/drivers/nvidia/*:* 2>/dev/null; do
  [ -e "\$d" ] || continue
  basename "\$d" > /sys/bus/pci/drivers/nvidia/unbind || true
done
EOF
chmod +x /usr/local/bin/disable-nvidia.sh

cat > /usr/local/bin/enable-nvidia.sh <<'EOF'
#!/usr/bin/env bash
# Rebind NVIDIA devices to driver (best-effort)
for d in /sys/bus/pci/devices/*; do
  vendor=\$(cat \$d/vendor 2>/dev/null || echo)
  if [ "\$vendor" = "0x10de" ]; then
    basename \$d > /sys/bus/pci/drivers/nvidia/bind || true
  fi
done
EOF
chmod +x /usr/local/bin/enable-nvidia.sh

# We do not enable these automatically. Use them for testing only.

# --- 11) Kernel module blacklisting for power (optional) ---
# If you want to blacklist nouveau (shouldn't be installed), ensure it is not loaded
cat > /etc/modprobe.d/blacklist-nouveau.conf <<'EOF'
blacklist nouveau
blacklist lbm-nouveau
options nouveau modeset=0
EOF

# --- 12) i915 tuning udev rule & I/O scheduler for NVMe ---
# I/O scheduler tweaks - set to none (default for NVMe is already good) and ensure writeback/latency friendly
cat > /etc/udev/rules.d/60-nvme-iops.rules <<'EOF'
ACTION=="add|change", KERNEL=="nvme[0-9]n[0-9]", ATTR{queue/scheduler}="none"
EOF

# --- 13) Lightweight KDE Plasma (Wayland-first) & SDDM ---
pacman -S --noconfirm \
    plasma-desktop \
    kde-gtk-config \
    kdeplasma-addons \
    plasma-wayland-session \
    xdg-desktop-portal \
    xdg-desktop-portal-kde \
    sddm \
    dolphin konsole plasma-nm ark kate

systemctl enable sddm

# SDDM Wayland configuration
mkdir -p /etc/sddm.conf.d
cat > /etc/sddm.conf.d/wayland.conf <<'EOF'
[General]
HaltCommand=/usr/bin/systemctl poweroff
RebootCommand=/usr/bin/systemctl reboot

[Wayland]
Session=plasmawayland
EnableHiDPI=true

[X11]
EnableHiDPI=true
EOF

# Avoid forcing software rendering by default — allow compositors to choose
cat > /etc/profile.d/kde_performance.sh <<'EOF'
# Helpful hints for KDE/Wayland sessions (do not force software rendering)
export KWIN_DRM_USE_MODIFIERS=1
EOF
chmod +x /etc/profile.d/kde_performance.sh

# --- 14) Users, sudo, and basic security ---
# Create user 'cole' if not present
if ! id -u cole >/dev/null 2>&1; then
  useradd -m -G wheel,audio,video,optical,storage,uucp,users cole
  echo "User 'cole' created. Run 'passwd cole' to set their password."
fi

# Ensure sudo is installed and wheel can sudo
if pacman -Qi sudo >/dev/null 2>&1; then
  sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers || true
fi

# Prompt to set passwords interactively (safer than embedding in script)
echo "Now set the root password (passwd):"
passwd

echo "Now set password for user 'cole' (passwd cole):"
passwd cole

# --- 15) Final housekeeping ---
# Update initramfs again to be safe
mkinitcpio -P

# Refresh systemd-boot metadata
bootctl update

# Clean package cache a bit
paccache -r || true

# Ensure periodic TRIM and TLP are enabled
systemctl enable --now fstrim.timer
systemctl enable --now tlp

# Optional: enable reflector timer if reflector is installed
if pacman -Qi reflector >/dev/null 2>&1; then
  systemctl enable --now reflector.timer || true
fi

# Ensure pacman-contrib for paccache cleanup
pacman -S --noconfirm pacman-contrib || true
paccache -r || true

# Disable smartd to avoid NVMe wakeups on laptops
systemctl disable --now smartd.service || true
