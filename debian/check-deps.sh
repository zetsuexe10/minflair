#!/usr/bin/env bash
# Checks what the Hyprland + Quickshell setup needs. Prints status per item and
# a ready-to-paste apt command for whatever is missing. Changes nothing.
# format: "command|apt package|what it is for"
items=(
 "Hyprland|hyprland|compositor (0.55+ for Lua config; trixie-backports)"
 "hyprctl|hyprland|hyprland control"
 "hypridle|hypridle|idle / sleep daemon"
 "hyprlock|hyprlock|lock screen (optional, shell has its own)"
 "hyprpicker|hyprpicker|colour picker (Super+Shift+C)"
 "hyprsunset|hyprsunset|night light"
 "xdg-desktop-portal-hyprland|xdg-desktop-portal-hyprland|screen share / screenshots portal"
 "swaybg|swaybg|wallpaper"
 "qs|quickshell|the shell"
 "kitty|kitty|terminal (Super+Return)"
 "nautilus|nautilus|file manager (Super+E)"
 "cliphist|cliphist|clipboard history"
 "wl-paste|wl-clipboard|clipboard"
 "socat|socat|keybind -> quickshell sockets"
 "brightnessctl|brightnessctl|brightness keys"
 "wpctl|wireplumber|volume keys"
 "playerctl|playerctl|media keys"
 "jq|jq|json in scripts"
 "python3|python3|shell helper scripts"
 "nm-applet|network-manager-gnome|network tray"
 "nmcli|network-manager|wifi panel"
 "bluetoothctl|bluez|bluetooth panel"
 "powerprofilesctl|power-profiles-daemon|power profiles / game mode"
 "gnome-keyring-daemon|gnome-keyring|secrets"
 "grim|grim|screenshots"
 "slurp|slurp|region select"
 "wf-recorder|wf-recorder|screen recording"
 "tesseract|tesseract-ocr|screenshot OCR"
 "magick|imagemagick|wallpaper colour extraction"
 "cava|cava|music visualizer"
 "notify-send|libnotify-bin|notifications"
 "gsettings|libglib2.0-bin|theme settings"
 "Xwayland|xwayland|X11 apps"
 "polkit agent|hyprpolkitagent|auth dialogs (or policykit-1-gnome)"
)
pkgs=(
 "adw-gtk3|adw-gtk3 GTK theme"
 "qt6-wayland|Qt wayland plugin"
 "qml6-module-qtquick-effects|QtQuick.Effects"
 "qml6-module-qtquick-shapes|QtQuick.Shapes"
 "qml6-module-qtquick-controls|QtQuick.Controls"
 "qml6-module-qtquick-layouts|QtQuick.Layouts"
 "python3-gi|python gobject"
 "python3-pam|lock screen auth"
 "upower|battery info"
 "papirus-icon-theme|icons"
 "xdg-desktop-portal-gtk|file dialogs"
)
have_cmd() { case "$1" in "polkit agent") command -v hyprpolkitagent >/dev/null || ls /usr/lib/*/polkit-gnome* /usr/lib/policykit-1-gnome/* /usr/libexec/hyprpolkitagent >/dev/null 2>&1;; *) command -v "$1" >/dev/null 2>&1;; esac; }
missing=()
printf '%-30s %-10s %s\n' ITEM STATUS NOTE
for it in "${items[@]}"; do
  IFS='|' read -r c p d <<<"$it"
  if have_cmd "$c"; then s=OK
  elif apt-cache policy "$p" 2>/dev/null | grep -q 'Candidate: [^(]'; then s="MISSING"; missing+=("$p")
  else s="MISSING*"; missing+=("$p"); fi
  printf '%-30s %-10s %s\n' "$c" "$s" "$d"
done
for it in "${pkgs[@]}"; do
  IFS='|' read -r p d <<<"$it"
  if dpkg -s "$p" >/dev/null 2>&1; then s=OK
  elif apt-cache policy "$p" 2>/dev/null | grep -q 'Candidate: [^(]'; then s=MISSING; missing+=("$p")
  else s="MISSING*"; missing+=("$p"); fi
  printf '%-30s %-10s %s\n' "$p" "$s" "$d"
done
echo; echo "MISSING* = no candidate in your enabled repos (hypr* tools: enable trixie-backports)."
if [ ${#missing[@]} -gt 0 ]; then
  echo; echo "Install the missing ones:"
  echo "  sudo apt install -y $(printf '%s\n' "${missing[@]}" | sort -u | tr '\n' ' ')"
  echo "(for hypr* packages from backports: sudo apt install -y -t trixie-backports <names>)"
fi
