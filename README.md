# Minflair for Debian 13 (trixie)

Quickshell desktop shell (Convex / Island / Gaming bar styles, control center, launcher, notifications,
clipboard, wallpaper selector, lock screen, ...) plus Hyprland dotfiles, ported from
[t4lentles5/minflair](https://github.com/t4lentles5/minflair) (GPL-3.0).

Requires Hyprland >= 0.55 (Lua config, from trixie-backports) and Quickshell (not in trixie: built by CI).

## Install
```bash
./check-deps.sh            # what is missing on your machine (changes nothing)
./install.sh --no-apt      # configs only, packages already installed
./install.sh               # CI zip only: also installs the Quickshell .deb and all packages
```
Then log out and start Hyprland. Put wallpapers in `~/Pictures/Wallpapers`; `Super+K` lists the keybinds.
Backups of your old `~/.config/quickshell` and `~/.config/hypr` are kept as `.bak.<date>`.

## Theme isolation
Minflair never edits `~/.config/gtk-*`, `~/.config/qt*ct` or gsettings. The wallpaper-driven GTK (adw-gtk3) and
Qt (qt6ct) theme is written to `~/.minflair/xdg`, which the Hyprland session uses as `XDG_CONFIG_HOME`
(every other entry is a symlink back to `~/.config`). Only apps started from the Minflair session see it.
Uninstall: `./uninstall.sh`, then delete `~/.minflair`.

## Differences from the Arch version
- apt/dpkg instead of pacman/yay; Package Manager window removed.
- Wallpapers via swaybg (no transitions). Only GTK, Qt and Hyprland colours are generated.
- Lock screen is Quickshell's (`Super+L`, hypridle); hyprlock is not used.

## Build
`.github/workflows/debian-trixie.yml` builds Quickshell on trixie, makes the `.deb`, smoke-tests the config and
publishes `minflair-quickshell-trixie.zip` (artifact; release asset on `v*` tags).
