#!/usr/bin/env bash
set -euo pipefail

echo "[*] Starting system bootstrap..."

# --- BASE SYSTEM ---
echo "[*] Updating base system..."
sudo pacman -Syu --noconfirm

echo "[*] Installing base packages..."
sudo pacman -S --noconfirm \
    linux linux-headers intel-ucode \
    nvidia nvidia-utils nvidia-settings \
    networkmanager bluez bluez-utils \
    git base-devel jq wget curl rsync \
    iwd

sudo systemctl enable --now NetworkManager
sudo systemctl enable --now bluetooth


# --- NVIDIA PRIME OFFLOAD ---
echo "[*] Configuring NVIDIA PRIME offload..."

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
echo "[*] Installing power & thermal tools..."
sudo pacman -S --noconfirm \
    tlp tlp-rdw powertop acpi_call zram-generator thermald

sudo systemctl enable --now tlp
sudo systemctl enable --now thermald
sudo systemctl enable --now fstrim.timer
sudo systemctl mask systemd-rfkill.service systemd-rfkill.socket

echo "[*] Intel GPU tuning..."
sudo tee /etc/modprobe.d/i915.conf >/dev/null <<EOF
options i915 enable_psr=1 enable_fbc=1
EOF


# --- DESKTOP ENVIRONMENT ---
echo "[*] Installing KDE Plasma..."
sudo pacman -S --noconfirm \
    plasma-meta sddm sddm-kcm \
    dolphin konsole \
    ark kate \
    xdg-desktop-portal xdg-desktop-portal-kde \
    kde-gtk-config kdeplasma-addons

sudo systemctl enable sddm


# --- DEV ENVIRONMENT ---
echo "[*] Installing development toolchain..."
sudo pacman -S --noconfirm \
    python python-pip python-virtualenv python-pynvim \
    nodejs npm rustup go \
    docker docker-compose

rustup default stable

sudo systemctl enable --now docker
sudo usermod -aG docker "$USER"


# --- NETWORKING / SECURITY ---
echo "[*] Installing networking & security tools..."
sudo pacman -S --noconfirm nmap wireshark-qt ufw reflector
sudo usermod -aG wireshark "$USER"

echo "[*] Configuring UFW firewall..."
sudo systemctl enable --now ufw
sudo ufw default deny incoming
sudo ufw default allow outgoing
yes | sudo ufw enable

echo "[*] Enabling reflector for fast mirrors..."
sudo systemctl enable --now reflector.timer


# --- FONTS ---
echo "[*] Installing fonts..."

sudo pacman -S --noconfirm \
    ttf-inter \
    ttf-fira-code \
    ttf-ubuntu-font-family

# Install yay if missing
if ! command -v yay >/dev/null 2>&1; then
    echo "[*] Installing yay (AUR helper)..."
    git clone https://aur.archlinux.org/yay.git /tmp/yay
    pushd /tmp/yay
    makepkg -si --noconfirm
    popd
fi

echo "[*] Installing Iosevka Extended..."
yay -S --noconfirm ttf-iosevka-extended

echo "[*] Updating font cache..."
sudo fc-cache -fv

# --- MACOS-TIER FONT RENDERING ---
echo "[+] Applying macOS-style font rendering..."

# Install freetype2 with subpixel rendering patches
sudo pacman -S --noconfirm freetype2 fontconfig cairo

# Create fontconfig config directory
sudo mkdir -p /etc/fonts/conf.d

# Enable subpixel rendering & light hinting (like macOS)
sudo tee /etc/fonts/conf.d/10-sub-pixel-rgb.conf >/dev/null <<EOF
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig>
  <match target="font">
    <edit mode="assign" name="rgba">
      <const>rgb</const>
    </edit>
  </match>
</fontconfig>
EOF

sudo tee /etc/fonts/conf.d/10-hinting-slight.conf >/dev/null <<EOF
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig>
  <match target="font">
    <edit mode="assign" name="hintstyle">
      <const>hintslight</const>
    </edit>
  </match>
</fontconfig>
EOF

sudo tee /etc/fonts/conf.d/10-antialias.conf >/dev/null <<EOF
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig>
  <match target="font">
    <edit mode="assign" name="antialias">
      <bool>true</bool>
    </edit>
  </match>
</fontconfig>
EOF

sudo tee /etc/fonts/conf.d/10-stem-darkening.conf >/dev/null <<EOF
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig>
  <match target="font">
    <edit name="lcdfilter" mode="assign">
      <const>lcddefault</const>
    </edit>
    <edit name="stem-darkening" mode="assign">
      <bool>true</bool>
    </edit>
  </match>
</fontconfig>
EOF

sudo fc-cache -fv

echo "==========================================="
echo "  Bootstrap Complete!"
echo "  Log out & back in for new groups to apply"
echo "==========================================="

