#!/usr/bin/env bash
# Builds ~/.minflair/xdg, the XDG_CONFIG_HOME used by the Minflair Hyprland session.
# gtk-3.0, gtk-4.0, qt5ct and qt6ct are Minflair-owned real dirs there; every other
# entry is a symlink to ~/.config, so apps keep their normal settings but only see
# the Minflair GTK/Qt theme. Your real ~/.config/gtk-* and qt*ct are never touched.
SRC="$HOME/.config"; DST="$HOME/.minflair/xdg"
OWN=" gtk-3.0 gtk-4.0 qt5ct qt6ct "
mkdir -p "$SRC" "$DST"
for d in gtk-3.0 gtk-4.0 qt5ct qt6ct; do mkdir -p "$DST/$d"; done

# adopt anything an app created inside the overlay, so its config lives in ~/.config
for e in "$DST"/* "$DST"/.[!.]*; do
  { [ -e "$e" ] || [ -L "$e" ]; } || continue
  n=$(basename "$e")
  case "$OWN" in *" $n "*) continue;; esac
  if [ ! -L "$e" ] && [ ! -e "$SRC/$n" ]; then mv "$e" "$SRC/$n" && ln -s "$SRC/$n" "$e"; fi
done
# link everything else from ~/.config
for e in "$SRC"/* "$SRC"/.[!.]*; do
  { [ -e "$e" ] || [ -L "$e" ]; } || continue
  n=$(basename "$e")
  case "$OWN" in *" $n "*) continue;; esac
  { [ -e "$DST/$n" ] || [ -L "$DST/$n" ]; } || ln -s "$e" "$DST/$n"
done
find "$DST" -maxdepth 1 -xtype l -delete 2>/dev/null

# first run: minimal GTK settings until the shell generates the real theme
for v in gtk-3.0 gtk-4.0; do
  [ -f "$DST/$v/settings.ini" ] || printf '[Settings]\ngtk-theme-name=adw-gtk3-dark\ngtk-application-prefer-dark-theme=1\n' > "$DST/$v/settings.ini"
done
exit 0
