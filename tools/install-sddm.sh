#!/usr/bin/env bash
# Optional: use the Minflair SDDM login theme (follows your wallpaper) instead of greetd.
# Takes effect on the next boot. Revert: sudo systemctl disable sddm; sudo systemctl enable --force greetd
set -euo pipefail
[ "$(id -u)" -ne 0 ] || { echo "Run as your normal user (sudo is used when needed)." >&2; exit 1; }
THEME_DIR=/usr/share/sddm/themes/minflair-sddm

echo "Current display manager: $(cat /etc/X11/default-display-manager 2>/dev/null || echo unknown)"
read -rp "Switch the login screen to SDDM (minflair theme)? [y/N] " a
[[ "$a" =~ ^[Yy]$ ]] || exit 0

sudo apt-get update
sudo apt-get install -y sddm acl git \
  qml6-module-qtquick qml6-module-qtquick-controls qml6-module-qtquick-layouts \
  qml6-module-qtquick-templates qml6-module-qtquick-window qml6-module-qt5compat-graphicaleffects \
  qml6-module-qtmultimedia qml6-module-qtqml-workerscript libqt6svg6 qt6-svg-plugins 2>/dev/null \
  || sudo apt-get install -y sddm acl git qml6-module-qt5compat-graphicaleffects qml6-module-qtquick-controls libqt6svg6
# the SDDM greeter runs on X11 by default
command -v Xorg >/dev/null || sudo apt-get install -y xserver-xorg-core xserver-xorg-input-libinput

tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
git clone --depth 1 https://github.com/t4lentles5/tokyo-night-sddm.git "$tmp/theme"
rm -rf "$tmp/theme/.git"
# the theme targets Qt5; trixie's SDDM is Qt6
if ldd "$(command -v sddm-greeter-qt6 || command -v sddm-greeter)" 2>/dev/null | grep -q Qt6; then
  grep -rl "QtGraphicalEffects" "$tmp/theme" | xargs -r sed -i 's/import QtGraphicalEffects.*/import Qt5Compat.GraphicalEffects/'
fi
sudo rm -rf "$THEME_DIR"; sudo mkdir -p "$(dirname "$THEME_DIR")"
sudo cp -a "$tmp/theme" "$THEME_DIR"; sudo chown -R root:root "$THEME_DIR"

sudo mkdir -p /etc/sddm.conf.d
printf '[Theme]\nCurrent=minflair-sddm\n' | sudo tee /etc/sddm.conf.d/minflair.conf >/dev/null

# wallpaper/colour sync folder written by the shell (world-writable like upstream)
sudo mkdir -p /var/tmp/sddm-theme && sudo chmod 777 /var/tmp/sddm-theme
[ -f "$HOME/.face" ] && { setfacl -m u:sddm:x "$HOME"; setfacl -m u:sddm:r "$HOME/.face"; } || true

# make SDDM the display manager (greetd stays installed, just disabled)
command -v greetd >/dev/null 2>&1 && sudo systemctl disable greetd.service 2>/dev/null || true
echo /usr/bin/sddm | sudo tee /etc/X11/default-display-manager >/dev/null
sudo systemctl enable --force sddm.service

echo "Done. Pick a wallpaper once (Ctrl+Alt+W) so the login screen gets its colours, then reboot."
echo "Preview without rebooting: sddm-greeter-qt6 --test-mode --theme $THEME_DIR"
