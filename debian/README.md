# Minflair - Debian 13 (trixie): Quickshell + Hyprland

Needs Hyprland >= 0.55 (Lua config; trixie-backports) and Quickshell (built by CI).

```bash
./install.sh            # full (CI zip): apt packages + configs
./install.sh --no-apt   # configs only, if the packages are already installed
```
Then log out and start Hyprland: `qs`, polkit agent, clipboard, idle lock all autostart.

## Theme isolation
Minflair never edits ~/.config/gtk-*, ~/.config/qt*ct or gsettings. Its GTK (adw-gtk3 + wallpaper colours) and
Qt (qt6ct) theme is written to `~/.minflair/xdg`. The Hyprland session sets `XDG_CONFIG_HOME=~/.minflair/xdg`,
an overlay that symlinks every other entry back to `~/.config`, so only apps started from the Minflair session
see the theme. Light/dark switches reach apps started after the change; restart Hyprland for the GTK_THEME env.
To remove everything: delete `~/.minflair` and `~/.config/hypr`.

## Differences from the Arch version
- Updates card / system info use apt/dpkg; Package Manager window removed.
- Wallpapers via swaybg (no transitions). Only GTK, Qt and Hyprland colours are generated (no kitty/nvim/sddm...).
- hyprlock isn't used: Super+L and hypridle call the Quickshell lock screen.
