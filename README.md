# Minflair for Debian 13 (trixie)

Quickshell desktop shell (Convex / Island / Gaming bar styles, control center, launcher, notifications,
clipboard, wallpaper selector, lock screen, ...) plus Hyprland dotfiles, ported from
[t4lentles5/minflair](https://github.com/t4lentles5/minflair) (GPL-3.0).

Requires Hyprland >= 0.55 (Lua config, from trixie-backports) and Quickshell (not in trixie: built by CI).

## Install
```bash
./tools/check-deps.sh      # what is missing on your machine (changes nothing)
./install.sh --no-apt      # configs only, packages already installed
./install.sh               # CI zip only: also installs the Quickshell .deb and all packages
```
Then log out and start Hyprland. Put wallpapers in `~/Pictures/Wallpapers`; `Super+K` lists the keybinds.
Backups of your old `~/.config/quickshell` and `~/.config/hypr` are kept as `.bak.<date>`.

## Login screen (optional)
`./tools/install-sddm.sh` switches greetd -> SDDM with the Minflair theme (follows your wallpaper). Takes effect on
next boot; revert with `sudo systemctl disable sddm; sudo systemctl enable --force greetd`.

## Something not showing (launcher, widgets)?
Inside Hyprland run `./tools/doctor.sh`. Widgets open through sockets `/tmp/quickshell_*` that only exist once the
shell has loaded without errors; the doctor prints the errors. Launcher is `Super+A`, control center `Ctrl+Alt+S`.

## Theme isolation
Minflair never edits `~/.config/gtk-*`, `~/.config/qt*ct` or gsettings. The wallpaper-driven GTK (adw-gtk3) and
Qt (qt6ct) theme is written to `~/.minflair/xdg`, which the Hyprland session uses as `XDG_CONFIG_HOME`
(every other entry is a symlink back to `~/.config`). Only apps started from the Minflair session see it.
Uninstall: `./uninstall.sh`, then delete `~/.minflair`.

## Differences from the Arch version
- apt/dpkg instead of pacman/yay; Package Manager window removed.
- Wallpapers via swaybg (no transitions). Only GTK, Qt and Hyprland colours are generated.
- Window rounding default is 12 (was 32). Lock screen is Quickshell's (`Super+L`, hypridle); hyprlock is not used.

## Build
`.github/workflows/debian-trixie.yml` builds Quickshell on trixie, makes the `.deb`, smoke-tests the config and
publishes `minflair-quickshell-trixie.zip` (artifact; release asset on `v*` tags).
