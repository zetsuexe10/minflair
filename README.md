# Minflair for Debian 13 (trixie)

Quickshell desktop shell (bar styles, launcher, control center, notifications, music, clipboard, wallpaper
selector, lock screen) with Hyprland dotfiles and an optional Quickshell login screen. Ported from
[t4lentles5/minflair](https://github.com/t4lentles5/minflair) (GPL-3.0).

## Requirements
- Hyprland 0.55+ (Lua config; `trixie-backports`)
- Quickshell 0.3 (not in trixie; the CI builds a `.deb`)
- Packages: `./tools/check-deps.sh` lists what is missing and changes nothing

Defaults: terminal `foot`, wallpapers `swaybg`, GTK theme `adw-gtk3`, cursor `Vimix-cursors` at size 16
(not packaged in Debian: `git clone https://github.com/vinceliuice/Vimix-cursors && cd Vimix-cursors && ./install.sh`;
Adwaita is used until it is installed).

## Install
```bash
./install.sh --no-apt              # configs only (packages already installed)
./install.sh --no-apt --greeter    # same, plus the login screen
./install.sh                       # CI zip only: also installs the .deb and all packages
```
Existing `~/.config/quickshell` and `~/.config/hypr` are moved to `.bak.<date>`.
Put wallpapers in `~/Pictures/Wallpapers`, then log in to a Hyprland session.

## Layout
| Path | Purpose |
| :-- | :-- |
| `config/quickshell/` | the shell, installed to `~/.config/quickshell` |
| `config/hypr/` | Hyprland config and helper scripts, installed to `~/.config/hypr` |
| `greeter/` | login screen (QML, `sessions.py`, `components/`, `assets/`) |
| `install.sh`, `uninstall.sh` | install / remove the user configs |
| `tools/check-deps.sh` | report missing packages |
| `tools/doctor.sh` | diagnose a shell that does not load or crashes |
| `tools/install-greeter.sh` | install or revert the login screen (root) |
| `tools/greeter-launch.sh` | greetd entry point (cage + Quickshell, gtkgreet fallback) |
| `ci/`, `.github/` | Quickshell `.deb` build, smoke test, release zip |

## Login screen
A Quickshell greeter that runs on greetd inside cage. It shows the user, password and a session picker with
readable names (Hyprland, Hyprland (uwsm), labwc, Openbox, FlickOS, ...), read from `/usr/share/wayland-sessions`
and `/usr/share/xsessions`. Colours and the blurred wallpaper follow the shell: choosing a wallpaper
(`Ctrl+Alt+W`) regenerates them.

```bash
sudo tools/install-greeter.sh            # install (disables SDDM, enables greetd)
sudo tools/install-greeter.sh --revert   # restore the original greeter
sudo systemctl restart greetd            # apply without rebooting (ends the graphical session)
```
If the greeter fails within a few seconds of starting, the stock gtkgreet screen is used instead.
Log: `/var/tmp/minflair-greeter/greeter.log`. The layout and icons are adapted from the Archcraft SDDM theme
(GPLv3, see `greeter/assets/NOTICE`).

## Keybinds (`Super+K` shows them in the shell)
`Super` = mod key.

| Apps | |
| :-- | :-- |
| `Super+Return` / `Super+Shift+Return` | foot / floating foot |
| `Super+E` / `Super+B` | file manager (nautilus) / browser |
| `Super+Shift+C` | colour picker |
| `Super+Space` | switch keyboard layout |

| Shell widgets | |
| :-- | :-- |
| `Super+A` | launcher (apps, calculator, `g`/`yt`/`w`/`gh`/`ddg` web search, `> settings`) |
| `Ctrl+Alt+S` | control center (wifi, bluetooth, volume, brightness) |
| `Ctrl+Alt+D` / `Ctrl+Alt+M` | dashboard / music |
| `Ctrl+Alt+N` / `Ctrl+Alt+C` | notifications / calendar |
| `Ctrl+Alt+F` / `Ctrl+Alt+T` | system usage / pomodoro |
| `Ctrl+Alt+W` | wallpaper selector (also regenerates the theme) |
| `Ctrl+Alt+X` | power menu |
| `Super+V` | clipboard history |
| `Super+Shift+S` | screenshot / recording |
| `Super+S` | Minflair settings |
| `Super+L` | lock screen |
| `Super+R` | restart the shell |

| Windows | |
| :-- | :-- |
| `Super+Q` | close |
| `Super+W` | toggle floating |
| `Super+F` / `Super+Shift+F` | maximize / fullscreen |
| `Super+J` / `Super+P` | toggle split / pseudo-tile |
| `Super+C` / `Super+Shift+P` | center floating / pin |
| `Super+N` / `Super+Shift+N` | minimize / restore minimized |
| `Super+G` / `Super+Tab` / `Super+Shift+G` | group / cycle group / lock group |
| `Super+Shift+M` | exit Hyprland |

| Navigation | |
| :-- | :-- |
| `Super+Arrows` | focus |
| `Super+Shift+Arrows` | move window |
| `Super+Alt+Arrows` | resize |
| `Super+Alt+Shift+Arrows` | swap |
| `Super+1..0` / `Super+Shift+1..0` | workspace / send window there |
| `Super+Ctrl+Left/Right`, `Super+Scroll` | previous / next workspace |
| `Super+Mouse left/right drag` | move / resize window |

Media, volume, brightness, mic-mute, touchpad and Caps/Num-lock keys work with an on-screen display.

## Troubleshooting
- Shell or a widget does not load, or `qs` crashes: run `./tools/doctor.sh` inside Hyprland and send the output.
  Widgets open through `/tmp/quickshell_*` sockets, which exist only after the shell loaded without errors.
  Crash reports are in `~/.cache/quickshell/crashes/`; the full log is `qs log`.
- Login screen: read `/var/tmp/minflair-greeter/greeter.log` and `sudo journalctl -b -u greetd`.
- Lock screen rejects the password: it authenticates through libpam; no extra Python package is needed.

## Theme isolation
Minflair never edits `~/.config/gtk-*`, `~/.config/qt*ct` or gsettings. The generated GTK (adw-gtk3) and Qt (qt6ct)
theme is written to `~/.minflair/xdg`, which the Hyprland session uses as `XDG_CONFIG_HOME` (every other entry
links back to `~/.config`). Only apps started from that session see it. To remove: `./uninstall.sh`, then delete `~/.minflair`.

## Differences from the Arch version
- apt/dpkg instead of pacman/yay; no Package Manager window; foot instead of kitty.
- swaybg instead of awww (no wallpaper transitions).
- Window rounding 12 (was 32); the lock screen is Quickshell's, hyprlock is not used.
- Only GTK, Qt, Hyprland and greeter colours are generated.

## Build
`.github/workflows/debian-trixie.yml` builds Quickshell on trixie, packages the `.deb`, smoke-tests the config and
publishes `minflair-quickshell-trixie.zip` (workflow artifact; release asset on `v*` tags).
