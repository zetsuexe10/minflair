#!/bin/sh
# Restore the last wallpaper at login (swaybg does not remember it). Falls back to a random
# image from ~/Pictures/Wallpapers when none was chosen yet.
cache="$HOME/.cache/quickshell"
dir="$HOME/Pictures/Wallpapers"
name=$(cat "$cache/current_wallpaper" 2>/dev/null)
case "$name" in /*) img="$name";; "") img="";; *) img="$dir/$name";; esac
if [ ! -f "$img" ]; then
  img=$(find -L "$dir" /usr/share/backgrounds -maxdepth 5 -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) 2>/dev/null | shuf -n 1)
fi
[ -n "$img" ] || { echo "no wallpaper found in $dir" >&2; exit 1; }
mode=$(python3 -c "import json,sys;print(json.load(open('$cache/settings_prefs.json')).get('wpResizeMode','crop'))" 2>/dev/null || echo crop)
exec "$HOME/.minflair/quickshell/Scripts/system/awww-compat.sh" img "$img" --resize "$mode"
