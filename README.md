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
sudo pacman -S hyprland quickshell python python-pillow socat wl-clipboard brightnessctl playerctl \
     swaybg grim slurp imagemagick networkmanager bluez bluez-utils pipewire wireplumber ttf-inter cava
git clone -b quickshell-side-island https://github.com/zetsuexe10/minflair ~/minflair
mkdir -p ~/.config && cp -r ~/minflair/config/quickshell ~/.config/quickshell
qs
```
Quickshell must be 0.3 or newer; if the repository version is older use `quickshell-git` from the AUR. Optional:
`adw-gtk3` (the GTK theme the shell recolours), `qt6ct`, `zenity` (file pickers). `cava` drives the media visualiser.

## Hyprland binds (hyprland.conf)
```
exec-once = qs
bind = SUPER, A,        exec, socat - UNIX-CONNECT:/tmp/quickshell_launcher
bind = SUPER, V,        exec, socat - UNIX-CONNECT:/tmp/quickshell_clipboard
bind = CTRL ALT, W,     exec, socat - UNIX-CONNECT:/tmp/quickshell_wallpaper
bind = CTRL ALT, X,     exec, socat - UNIX-CONNECT:/tmp/quickshell_powerMenu
bind = CTRL ALT, S,     exec, socat - UNIX-CONNECT:/tmp/quickshell_controlCenter
bind = CTRL ALT, D,     exec, socat - UNIX-CONNECT:/tmp/quickshell_dashboard
bind = CTRL ALT, N,     exec, socat - UNIX-CONNECT:/tmp/quickshell_notificationsCenter
bind = CTRL ALT, C,     exec, socat - UNIX-CONNECT:/tmp/quickshell_calendar
bind = CTRL ALT, M,     exec, socat - UNIX-CONNECT:/tmp/quickshell_music
bind = CTRL ALT, F,     exec, socat - UNIX-CONNECT:/tmp/quickshell_systemUsage
bind = SUPER SHIFT, S,  exec, socat - UNIX-CONNECT:/tmp/quickshell_screenshot
bind = SUPER CTRL, S,   exec, socat - UNIX-CONNECT:/tmp/quickshell_minflair_side_settings
bind = SUPER ALT, 1,    exec, qs ipc call bar set island
bind = SUPER ALT, 2,    exec, qs ipc call bar set side
bind = SUPER ALT, 3,    exec, qs ipc call bar set pill
bind = SUPER ALT, B,    exec, qs ipc call bar cycle
bind = SUPER, X,        exec, qs ipc call bar powermenu
```
With Hyprland's Lua config: `hl.bind(mod .. " + A", hl.dsp.exec_cmd("socat - UNIX-CONNECT:/tmp/quickshell_launcher"))`.
The default style is Island; pick another in Settings > Bar or with the binds above.

## Side and Pill
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
