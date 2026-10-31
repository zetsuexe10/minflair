#!/usr/bin/env bash
# Minflair Quickshell config - Debian 13 (trixie) installer. Run as your normal user.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[ "$(id -u)" -ne 0 ] || { echo "Run as your normal user, not root." >&2; exit 1; }

echo "==> Installing packages (sudo)"
sudo apt-get update
# Quickshell (built by CI) + everything the shell calls at runtime.
sudo apt-get install -y "$HERE"/debs/quickshell_*.deb \
  python3 python3-gi python3-pam socat jq imagemagick \
  network-manager bluez power-profiles-daemon upower \
  pipewire pipewire-pulse wireplumber playerctl brightnessctl \
  wl-clipboard cliphist grim slurp wf-recorder tesseract-ocr tesseract-ocr-eng \
  cava swaybg libnotify-bin xdg-utils papirus-icon-theme fonts-noto-color-emoji \
  fonts-noto-core qt6ct

echo "==> Installing config to ~/.config/quickshell"
dest="$HOME/.config/quickshell"
if [ -e "$dest" ]; then
  bak="$HOME/.config/quickshell.bak.$(date +%Y%m%d_%H%M%S)"
  mv "$dest" "$bak"; echo "    existing config moved to $bak"
fi
mkdir -p "$HOME/.config"
cp -a "$HERE/config/quickshell" "$dest"
find "$dest" \( -name '*.sh' -o -name '*.py' \) -exec chmod +x {} +

echo
echo "Done. Start it inside a Wayland session with:  qs"
echo "Logs: qs log     Optional: install 'awww' for animated wallpaper transitions (swaybg is used otherwise)."
