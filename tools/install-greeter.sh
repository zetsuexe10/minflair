#!/usr/bin/env bash
# Installs the Minflair login screen (Quickshell greeter) on a greetd/FlickOS system.
#   sudo tools/install-greeter.sh            install
#   sudo tools/install-greeter.sh --revert   restore the original greeter
set -euo pipefail

[[ $EUID -eq 0 ]] || { echo "Run with sudo."; exit 1; }
HERE="$(cd "$(dirname "$0")/.." && pwd)"
WRAP=/usr/libexec/flickos/greeter
DEST=/usr/share/minflair/greeter

if [[ "${1:-}" == "--revert" ]]; then
  if [[ -f "$WRAP.orig" ]]; then
    mv -f "$WRAP.orig" "$WRAP"
    echo "Restored the original greeter."
  else
    echo "No backup found at $WRAP.orig."
  fi
  exit 0
fi

command -v cage >/dev/null || { echo "cage is missing: apt install cage"; exit 1; }
command -v greetd >/dev/null || { echo "greetd is missing: apt install greetd"; exit 1; }
QS="$(command -v quickshell || command -v qs || true)"
[[ -n "$QS" ]] || { echo "quickshell not found in PATH"; exit 1; }
"$QS" --version >/dev/null 2>&1 || true
python3 -c 'import pwd' || exit 1

# Make sure greetd (not SDDM) is the display manager.
if systemctl is-enabled sddm >/dev/null 2>&1; then
  systemctl disable sddm || true
fi
systemctl enable greetd || true
echo "$(command -v greetd)" > /etc/X11/default-display-manager 2>/dev/null || true

install -d "$DEST"
cp -a "$HERE/greeter/." "$DEST/"
install -d -m 777 /var/tmp/minflair-greeter

if [[ -f "$WRAP" && ! -f "$WRAP.orig" ]]; then
  cp -a "$WRAP" "$WRAP.orig"
fi
install -D -m 755 "$HERE/tools/greeter-launch.sh" "$WRAP"

echo "Done. Open Quickshell once in your session so the palette and wallpaper are"
echo "written to /var/tmp/minflair-greeter, then reboot (or: sudo systemctl restart greetd)."
echo "Revert: sudo tools/install-greeter.sh --revert"
