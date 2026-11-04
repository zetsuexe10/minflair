# Minflair Quickshell: Island, Side and Pill

The Quickshell configuration of Minflair for **Arch Linux** (and anything else with Hyprland and Quickshell 0.3 or
newer). Only the Quickshell config is here: no compositor config, greeter or installer.

| Style | What it is |
| :-- | :-- |
| Island | the dynamic-island top bar, widgets expand out of it |
| Side | a Caelestia-style frame around the screen with the bar on one edge and panels that grow out of it |
| Pill | a floating dynamic island on any edge: a small capsule that grows into the full bar |

Side and Pill share one palette (AMOLED by default), the Caelestia dashboard (Dashboard, Media, Performance, Weather),
launcher, power panel, Wi-Fi / Bluetooth / sound popouts and the shell settings panel.

## Install
```sh
git clone -b quickshell-side-island https://github.com/zetsuexe10/minflair ~/minflair
cd ~/minflair
./install.sh
```
The installer asks before every step and takes the bracketed default on enter. For no questions at all:
```sh
./install.sh --yes
./install.sh --yes --style pill --terminal kitty --files thunar --layout us,es
```
| Option | Effect |
| :-- | :-- |
| `-y`, `--yes` | answer yes to everything and use the defaults |
| `--style island\|side\|pill` | starting bar style |
| `--terminal foot\|kitty\|alacritty\|wezterm` | terminal for `Super+Return` |
| `--files nautilus\|thunar\|dolphin` | file manager for `Super+E` |
| `--layout us,es` | keyboard layouts |
| `--no-packages`, `--no-shell`, `--no-hypr`, `--no-session`, `--no-services` | skip a step |
| `--aur-helper paru\|yay` | helper for packages that are not in the repositories |
| `--check` | report what is installed and what is missing, change nothing |

What it does: installs the packages with pacman (AUR helper for anything missing), checks Hyprland is 0.55 or newer and
Quickshell 0.3 or newer, copies `config/quickshell` to `~/.config/quickshell` and `config/hypr` to `~/.config/hypr`
(existing ones are moved to `~/.minflair/backup/<date>`), writes your choices to `~/.config/hypr/local.lua`, sets the bar
style, installs the **Minflair** session and enables NetworkManager and Bluetooth. `./uninstall.sh` reverses it and
offers your previous configs back. Packages are never removed.

## Session
The installer adds `/usr/share/wayland-sessions/minflair.desktop`, so **Minflair** appears in SDDM, GDM, greetd, ly and
other display managers instead of "Hyprland". It runs `~/.minflair/bin/minflair-session`, which starts Hyprland with
`~/.config/hypr/hyprland.lua` and logs to `~/.local/state/minflair/session.log`. From a TTY run that script directly.
`XDG_SESSION_DESKTOP` is `Minflair`; `XDG_CURRENT_DESKTOP` stays `Hyprland` so portals pick the Hyprland backend.
Put extra variables for the session in `~/.minflair/session.env`.

## Hyprland config
`config/hypr` is a Hyprland 0.55 Lua config: `hyprland.lua` loads `animations`, `autostart`, `envs`, `keybinds`,
`monitors`, `userprefs` and `windowrules`. `local.lua` holds what the installer asked for (terminal, floating terminal
command, file manager, keyboard layout). Autostart skips anything that is not installed. `keybinds.lua` is the full list;
the shell shows it in its keybinds cheat sheet. The shell's GTK/Qt theme lives in `~/.minflair`, your `~/.config/gtk-*`
and `qt*ct` are not touched.

Main binds (`Super` is the logo key):
```
Super+Return        terminal            Super+Shift+Return  floating terminal
Super+E             file manager        Super+A             launcher
Super+V             clipboard           Super+L             lock
Super+Shift+D       dashboard           Super+Shift+A       control center
Super+Shift+W       wallpapers          Super+Shift+S       screenshot
Super+X             power menu (Pill)   Super+Alt+1/2/3     island / side / pill
```
The Quickshell panels are toggled through sockets, so any other keybinding tool can use
`socat - UNIX-CONNECT:/tmp/quickshell_<panel>` with `launcher`, `clipboard`, `wallpaper`, `powerMenu`,
`controlCenter`, `dashboard`, `notificationsCenter`, `calendar`, `music`, `systemUsage`, `screenshot`.
The default style is Island; change it in Settings > Bar or with `qs ipc call bar set island|side|pill`.

## Side and Pill
**Dynamic bar (Side):** Settings > Bar > Dynamic bar shrinks the bar to a small capsule with the workspaces, the clock
and the song that is playing (only while a player is running). Hovering the capsule grows it back to the full bar and
it shrinks again when the pointer leaves; with "Expand on hover" off, click the capsule instead, and "Keep expanded"
turns the shrinking off. Hovering or clicking the song opens a compact player (cover, title, seek bar, previous, play,
next) that grows out of the bar's edge, centred on the song.

**Bar entries** (each can be turned off): launcher, workspaces, focused window title, tray, status icons (network,
Bluetooth, volume, brightness, keyboard layout, lock keys, notifications), clock, power. The bar sits on the left,
right, top or bottom. Scrolling the first half of the bar changes volume, the second half brightness, and scrolling the
workspaces switches workspace.

**Workspaces** use Caelestia's switcher: circles for empty, rounded squares for occupied, a polygon that changes shape
for the active one, with a sliding, stretching pill. Numbers and app-icon styles are in settings.

**Dashboard:** the user card shows your logo image, then `~/.face`, then the distro logo, then your initial. The OS
row shows the OS brand read from `/etc/issue` and `os-release`; "OS name" in settings overrides it. The Media tab
follows Caelestia's: cookie-shaped cover with an audio-reactive ring (needs `cava`), wavy seek bar, shuffle / previous /
play / next / repeat, synced lyrics from lrclib.net and a player selector. With no player chosen in settings it
follows whatever is playing.

**Side** is a frame around the screen with panels that grow out of it: power panel on the right edge, dashboard on the
top edge, launcher on the bottom edge, other panels from their bar icons.

**Pill** is a capsule that floats over the desktop. At rest it shows the time (or workspaces or window title) and
morphs: workspaces when you switch, cover and title when a new song starts, the level when you change volume or
brightness. Hover to grow it into the full bar, or keep it expanded. Panels open from its edge, centred on it; the wallpaper and screenshot panels grow out of the capsule itself, like the Island bar's, and the launcher opens at the bottom. The power button and `Super+X` open the power menu in the middle of the screen.
Shell settings > Pill: Reserve space, Keep expanded, Idle view, Alignment, Offset.

**Wallpapers:** `~/Pictures/Wallpapers` and `/usr/share/backgrounds` (subfolders included), editable in settings. Arrow
keys browse, Enter sets. The wallpaper and screenshot panels drop from the bar's edge.

**Shell settings** (`Super+Ctrl+S`): Bar, Pill, Frame & Style, App Appearance, Wallpapers, Panels, GitHub, Shortcuts.

## App Appearance
GTK theme, app font and size, icon theme, cursor theme and size. Written to `~/.minflair` (an `XDG_CONFIG_HOME`
overlay that links back to `~/.config`), never to `~/.config/gtk-*`, `qt*ct` or gsettings. Apps started from the
launcher use it at once; for the whole session add to hyprland.conf:
```
env = XDG_CONFIG_HOME,$HOME/.minflair/xdg
env = QT_QPA_PLATFORMTHEME,qt6ct
```
The shell font is separate from the app font.

## Troubleshooting
- Nothing loads: run `qs` in a terminal and read the errors; `qs log` shows the last run.
- Keys do nothing inside the launcher, wallpaper selector or screenshot panel: run `qs log | grep "side overlay focus"`
  right after opening the launcher and send the output.
- Package updates are detected for pacman, AUR (paru/yay), apt and dnf.
