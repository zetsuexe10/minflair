#!/usr/bin/env bash
# Minflair (Quickshell + Hyprland) for Debian 13. Run as your normal user.
#   ./install.sh            full: apt packages + configs      (zip from CI, has debs/)
#   ./install.sh --no-apt   configs only (you already installed the packages)
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[ "$(id -u)" -ne 0 ] || { echo "Run as your normal user, not root." >&2; exit 1; }

if [ "${1:-}" != "--no-apt" ] && ls "$HERE"/debs/quickshell_*.deb >/dev/null 2>&1; then
  echo "==> Installing packages (sudo)"
  sudo apt-get update
  sudo apt-get install -y "$HERE"/debs/quickshell_*.deb \
    python3 python3-gi python3-pam socat jq imagemagick network-manager network-manager-gnome bluez \
    power-profiles-daemon upower pipewire pipewire-pulse wireplumber playerctl brightnessctl \
    wl-clipboard cliphist grim slurp wf-recorder tesseract-ocr tesseract-ocr-eng cava swaybg \
    libnotify-bin xdg-utils papirus-icon-theme fonts-noto-color-emoji fonts-noto-core qt6ct \
    kitty nautilus gnome-keyring xdg-desktop-portal-gtk qt6-wayland
  sudo apt-get install -y -t trixie-backports hyprland hypridle hyprlock hyprpicker hyprsunset \
    hyprpolkitagent xdg-desktop-portal-hyprland \
    || echo "!! hypr* packages: enable trixie-backports and install them manually"
fi

backup() { # backup <dir>
  if [ -e "$1" ]; then
    b="$1.bak.$(date +%Y%m%d_%H%M%S)"; mv "$1" "$b"; echo "    $1 -> $b"
  fi
}
mkdir -p "$HOME/.config"
for d in quickshell hypr; do
  echo "==> Installing ~/.config/$d"
  backup "$HOME/.config/$d"
  cp -a "$HERE/config/$d" "$HOME/.config/$d"
  find "$HOME/.config/$d" \( -name '*.sh' -o -name '*.py' \) -exec chmod +x {} +
done
mkdir -p "$HOME/Pictures/Wallpapers"
"$HOME/.config/hypr/scripts/minflair-env.sh"

cat <<MSG

Done.
 - Log out, pick/start Hyprland, and everything (qs, themes) starts by itself.
 - Theme output lives in ~/.minflair; your ~/.config/gtk-*, qt*ct and gsettings are untouched.
 - Put wallpapers in ~/Pictures/Wallpapers. Keybinds: Super+K shows all of them.
 - Logs: qs log
MSG
