#!/usr/bin/env bash
set -e 

# Official repo fonts from arch
sudo pacman -S --noconfirm \
    ttf-inter \
    ttf-fira-code \
    ttf-ubuntu-font-family

# AUR helper check
if ! command -v yay &>/dev/null; then
    git clone https://aur.archlinux.org/yay.git /tmp/yay
    cd /tmp/yay
    makepkg -si --noconfirm
    cd -
fi

# Install iosevka (the best font ever)
yay -S --noconfirm ttf-iosevka-extended

# Update font cache
sudo fc-cache -fv

