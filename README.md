# Minflair for Debian 13 (trixie)

Quickshell desktop shell (Convex / Island / Gaming bar styles, launcher, control center, notifications, music,
clipboard, wallpaper selector, lock screen, ...), Hyprland dotfiles and a Quickshell login screen (greetd) with a session picker.
Ported from [t4lentles5/minflair](https://github.com/t4lentles5/minflair) (GPL-3.0).

Needs Hyprland >= 0.55 (Lua config, from trixie-backports) and Quickshell (not in trixie: built by CI).
Default terminal: **foot**. Login screen: Quickshell greeter on greetd + cage (optional).

## Install
```bash
./tools/check-deps.sh      # what is missing on your machine (changes nothing)
./install.sh --no-apt      # configs only, packages already installed
./install.sh               # CI zip only: also installs the Quickshell .deb and all packages
```
Flag: `--no-apt` skips packages. Old `~/.config/quickshell` and
`~/.config/hypr` are kept as `.bak.<date>`. Put wallpapers in `~/Pictures/Wallpapers`, then log out and pick a session.

## Login screen
Optional: `sudo tools/install-greeter.sh` installs a Quickshell greeter that runs under greetd + cage (same blurred wallpaper,
header, clock, pill user/password fields, **session picker** with real names: Hyprland, labwc, Openbox, FlickOS, ...). It uses your
wallpaper colours after you pick one in the shell. If it fails to start, the stock gtkgreet screen is used instead.
Layout and icons are adapted from the Archcraft SDDM theme (GPLv3, credit in `greeter/Assets/NOTICE`). Debug log: `/var/tmp/minflair-greeter/greeter.log`.
Revert: `sudo tools/install-greeter.sh --revert`. Coming back from SDDM: `sudo systemctl disable sddm; sudo systemctl enable --force greetd`.

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

## Problems?
Lock screen password rejected? It needs only libpam (no python package). Run `./tools/doctor.sh` inside Hyprland. Widgets open through `/tmp/quickshell_*` sockets that exist only once the
shell has loaded without errors; the doctor prints those errors (`qs log` shows the full log). If `qs` crashes, the
report is in `~/.cache/quickshell/crashes/`.

## Theme isolation
Minflair never edits `~/.config/gtk-*`, `~/.config/qt*ct` or gsettings. The wallpaper-driven GTK (adw-gtk3) and
Qt (qt6ct) theme goes to `~/.minflair/xdg`, used as `XDG_CONFIG_HOME` by the Hyprland session (every other entry
links back to `~/.config`). Only apps started from the Minflair session see it. Uninstall: `./uninstall.sh`, delete `~/.minflair`.

## Differences from the Arch version
- apt/dpkg instead of pacman/yay; Package Manager window removed. foot instead of kitty.
- Wallpapers via swaybg (no transitions). Only GTK, Qt, Hyprland and greeter colours are generated.
- Window rounding default 12 (was 32). Lock screen is Quickshell's; hyprlock is not used.

## Build
`.github/workflows/debian-trixie.yml` builds Quickshell on trixie, makes the `.deb`, smoke-tests the config and
publishes `minflair-quickshell-trixie.zip` (artifact; release asset on `v*` tags).
