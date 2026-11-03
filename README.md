# Minflair Quickshell: Island, Side and Pill

The Quickshell configuration of Minflair with three bar styles, for **Arch Linux** (and anything else with
Hyprland and Quickshell 0.3 or newer):

- **Side**: a Caelestia-style desktop. A frame around the screen, hover panels, a Caelestia dashboard (Dashboard / Media / Performance / Weather), a bottom
  launcher, power panel, volume/brightness OSD, Wi-Fi / Bluetooth / sound popouts and its own settings panel. AMOLED by default.
- **Island**: the dynamic-island bar, with widgets expanding out of it.
- **Pill**: a floating dynamic island on any edge. A small capsule that morphs between the time, the workspaces
  (they pop in when you switch) and the active window; hover grows it into the whole bar, or keep it expanded in settings.

Only the Quickshell config is in this branch: no compositor config, greeter or installer.

## Install
```sh
sudo pacman -S hyprland quickshell python python-pillow socat wl-clipboard brightnessctl playerctl \
     swaybg grim slurp imagemagick networkmanager bluez bluez-utils pipewire wireplumber ttf-inter
# quickshell must be 0.3+; if the repo version is older use quickshell-git from the AUR
git clone -b quickshell-side-island https://github.com/zetsuexe10/minflair ~/minflair
mkdir -p ~/.config && cp -r ~/minflair/config/quickshell ~/.config/quickshell
qs            # or: exec-once = qs   in your Hyprland config
```
Optional: `paru -S adw-gtk3` for the GTK theme the shell recolours, `qt6ct` for Qt apps, `zenity` for file pickers.

## Hyprland binds (hyprland.conf)
```
exec-once = qs
bind = SUPER, A,      exec, socat - UNIX-CONNECT:/tmp/quickshell_launcher
bind = SUPER, V,      exec, socat - UNIX-CONNECT:/tmp/quickshell_clipboard
bind = CTRL ALT, W,   exec, socat - UNIX-CONNECT:/tmp/quickshell_wallpaper
bind = CTRL ALT, X,   exec, socat - UNIX-CONNECT:/tmp/quickshell_powerMenu
bind = CTRL ALT, S,   exec, socat - UNIX-CONNECT:/tmp/quickshell_controlCenter
bind = SUPER SHIFT, S, exec, socat - UNIX-CONNECT:/tmp/quickshell_screenshot
bind = SUPER CTRL, S, exec, socat - UNIX-CONNECT:/tmp/quickshell_minflair_side_settings
bind = SUPER ALT, 1,  exec, qs ipc call bar set island
bind = SUPER ALT, 2,  exec, qs ipc call bar set side
bind = SUPER ALT, 3,  exec, qs ipc call bar set pill
```
With Hyprland's Lua config use `hl.bind(mod .. " + A", hl.dsp.exec_cmd("socat - UNIX-CONNECT:/tmp/quickshell_launcher"))`.

## Side style
- **Settings** (`Super+Ctrl+S`): bar position and entries, launcher button image, the Pill page (keep expanded, idle view, alignment, offset),
  colours (AMOLED / Dark / Light / follow theme), hover panels, dashboard and weather, wallpaper folders, GitHub,
  and **App Appearance**.
- **Pill** (`Super+Alt+4` style): Settings > Pill. Idle view (time, workspaces or window), keep expanded, edge (Bar > Position),
  alignment and offset.
- **Wallpapers** (and screenshot) drop from the top edge: `~/Pictures/Wallpapers` and `/usr/share/backgrounds` (subfolders too). Arrow keys browse, Enter sets.
- **Scroll** the first half of the bar for volume, the second half for brightness, the workspaces to switch.

## App Appearance (GTK / Qt, this shell only)
GTK theme, app font and size, icon theme, cursor theme and size. Written to `~/.minflair` (an `XDG_CONFIG_HOME` overlay
that links back to `~/.config`), never to `~/.config/gtk-*`, `qt*ct` or gsettings. Apps started afterwards use it; for a
permanent effect add to hyprland.conf:
```
env = XDG_CONFIG_HOME,$HOME/.minflair/xdg
env = QT_QPA_PLATFORMTHEME,qt6ct
```
The shell font is separate from the app font.

## Troubleshooting
- Nothing loads: run `qs` in a terminal and read the errors; `qs log` shows the last run.
- Keyboard does not work in the launcher/wallpaper picker: run `qs log | grep "side overlay focus"` and send the output.
- Package updates are detected for pacman, AUR (paru/yay), apt and dnf.
