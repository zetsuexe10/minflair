#!/usr/bin/env bash
# Installs the Minflair SDDM login screen (wallpaper-synced, with a session picker) and makes
# SDDM the display manager instead of greetd. Takes effect on next boot.
#   ./install-sddm.sh        asks first        ./install-sddm.sh -y   no questions
# Revert: sudo systemctl disable sddm; sudo systemctl enable --force greetd
set -euo pipefail
[ "$(id -u)" -ne 0 ] || { echo "Run as your normal user (sudo is used when needed)." >&2; exit 1; }
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
THEME_DIR=/usr/share/sddm/themes/minflair
[ -f "$ROOT/sddm/minflair/Main.qml" ] || { echo "theme not found in $ROOT/sddm" >&2; exit 1; }

echo "Current display manager: $(cat /etc/X11/default-display-manager 2>/dev/null || echo unknown)"
if [ "${1:-}" != "-y" ]; then
  read -rp "Switch the login screen to SDDM (Minflair theme)? [y/N] " a
  [[ "$a" =~ ^[Yy]$ ]] || exit 0
fi

sudo apt-get update
sudo apt-get install -y sddm acl \
  qml6-module-qtquick qml6-module-qtquick-controls qml6-module-qtquick-layouts \
  qml6-module-qtquick-templates qml6-module-qtquick-window qml6-module-qtquick-effects \
  qml6-module-qtqml-workerscript
# the SDDM greeter runs on X11 by default
command -v Xorg >/dev/null || sudo apt-get install -y xserver-xorg-core xserver-xorg-input-libinput
# other sessions to pick from at login (SDDM lists every installed one); optional
sudo apt-get install -y labwc openbox 2>/dev/null || echo "(labwc/openbox not installed; apt install them if you want them in the list)"

sudo rm -rf "$THEME_DIR"; sudo mkdir -p "$(dirname "$THEME_DIR")"
sudo cp -a "$ROOT/sddm/minflair" "$THEME_DIR"; sudo chown -R root:root "$THEME_DIR"
sudo mkdir -p /etc/sddm.conf.d
printf '[Theme]\nCurrent=minflair\n' | sudo tee /etc/sddm.conf.d/minflair.conf >/dev/null

# folder where the shell drops the wallpaper + palette for the greeter
sudo mkdir -p /var/tmp/sddm-theme && sudo chmod 777 /var/tmp/sddm-theme

# make SDDM the display manager (greetd stays installed, just disabled)
command -v greetd >/dev/null 2>&1 && sudo systemctl disable greetd.service 2>/dev/null || true
echo /usr/bin/sddm | sudo tee /etc/X11/default-display-manager >/dev/null
sudo systemctl enable --force sddm.service

echo
echo "Done. Pick a wallpaper once (Ctrl+Alt+W) so the login screen gets its colours, then reboot."
echo "Sessions in the picker: $(ls /usr/share/wayland-sessions /usr/share/xsessions 2>/dev/null | grep desktop | tr '\n' ' ')"
