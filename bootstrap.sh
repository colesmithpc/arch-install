#!/usr/bin/env bash

# --- BASE SYSTEM ---
sudo pacman -Syu --noconfirm
sudo pacman -S --noconfirm linux linux-headers intel-ucode \
nvidia nvidia-utils nvidia-settings \
networkmanager bluez bluez-utils \
git base-devel jq wget curl rsync

sudo systemctl enable --now NetworkManager
sudo systemctl enable --now bluetooth

# --- NVIDIA PRIME OFFLOAD ---
sudo tee /etc/modprobe.d/nvidia.conf >/dev/null <<EOF
options nvidia NVreg_DynamicPowerManagement=0x02
options nvidia_drm modeset=1
EOF

sudo tee /etc/modules-load.d/nvidia.conf >/dev/null <<EOF
nvidia
nvidia_modeset
nvidia_uvm
nvidia_drm
EOF

sudo tee /usr/local/bin/prime-run >/dev/null <<'EOF'
#!/usr/bin/env bash
__NV_PRIME_RENDER_OFFLOAD=1 \
__GLX_VENDOR_LIBRARY_NAME=nvidia \
__VK_LAYER_NV_optimus=NVIDIA_only \
"$@"
EOF
sudo chmod +x /usr/local/bin/prime-run

# --- POWER & THERMALS ---
sudo pacman -S --noconfirm tlp tlp-rdw powertop acpi_call zram-generator thermald
sudo systemctl enable --now tlp thermald fstrim.timer
sudo systemctl mask systemd-rfkill.service systemd-rfkill.socket

# Intel GPU tuning
sudo tee /etc/modprobe.d/i915.conf >/dev/null <<EOF
options i915 enable_psr=1 enable_fbc=1
EOF

# --- DESKTOP ENVIRONMENT ---
sudo pacman -S --noconfirm plasma-meta sddm sddm-kcm dolphin konsole \
xdg-desktop-portal xdg-desktop-portal-kde \
kde-gtk-config kdeplasma-addons ark kate
sudo systemctl enable sddm

# --- DEV ENVIRONMENT ---
sudo pacman -S --noconfirm python python-pip python-virtualenv python-pynvim \
nodejs npm rustup go docker docker-compose

rustup default stable

sudo systemctl enable --now docker
sudo usermod -aG docker $USER

# --- NETWORKING / SECURITY ---
sudo pacman -S --noconfirm nmap wireshark-qt ufw reflector
sudo usermod -aG wireshark $USER

# UFW defaults
sudo systemctl enable --now ufw
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw enable

sudo systemctl enable --now reflector.timer
