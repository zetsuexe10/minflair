# Minflair for Arch Linux

The Minflair Quickshell shell and a Hyprland (Lua) config, with an installer that keeps everything in `~/.minflair`.
Your own `~/.config/hypr`, `~/.config/quickshell` and other dotfiles are never read, replaced or changed, and your
other Hyprland and Quickshell setups keep running as they are.

| # | Style | What it is | Switch |
| :-: | :-- | :-- | :-- |
| 1 | Convex | the original top bar with a curved centre | `Super+Alt+1` |
| 2 | Island | the dynamic-island top bar, widgets expand out of it | `Super+Alt+2` |
| 3 | Side | a Caelestia-style frame around the screen, bar on one edge, panels grow out of it | `Super+Alt+3` |

`Super+Alt+B` cycles the styles, `Super+Alt+Shift+B` goes back, or use Settings > Bar. The default is Island.

## Install

```sh
git clone -b quickshell-side-island https://github.com/zetsuexe10/minflair ~/minflair
cd ~/minflair
./install.sh
```

The installer asks before each step and takes the bracketed default on enter. `--yes` answers yes to everything.

| Option | Effect |
| :-- | :-- |
| `-y`, `--yes` | answer yes to everything and use the defaults |
| `--style convex\|island\|side` | starting bar style |
| `--terminal foot\|kitty\|alacritty\|wezterm` | terminal for `Super+Return` |
| `--files nautilus\|thunar\|dolphin` | file manager for `Super+E` |
| `--layout us,es` | keyboard layouts |
| `--no-packages`, `--no-shell`, `--no-hypr`, `--no-session`, `--no-services` | skip a step |
| `--aur-helper paru\|yay` | helper for packages that are not in the repositories |
| `--check` | report what is installed and what is missing, change nothing |

```sh
./install.sh --yes --style side --terminal kitty --files thunar --layout us,es
```

| Step | What it does |
| :-- | :-- |
| Packages | pacman for repository packages, an AUR helper for the rest; checks Hyprland 0.55+ and Quickshell 0.3+ |
| Shell | copies `config/quickshell` to `~/.minflair/quickshell`, sets the starting style |
| Hyprland | copies `config/hypr` to `~/.minflair/hypr`, writes your choices to `~/.minflair/hypr/local.lua` |
| Launchers | `~/.minflair/bin/qs` and `~/.minflair/bin/minflair-session` |
| Session | adds **Minflair** to `/usr/share/wayland-sessions` (sudo) |
| Services | enables NetworkManager and Bluetooth (sudo) |

Reinstalling moves the previous `~/.minflair/quickshell` and `~/.minflair/hypr` to `~/.minflair/backup/<date>`.
`./uninstall.sh` removes the session entry and `~/.minflair` (`--keep-data` keeps the theme output and backups). It
never touches `~/.config` and never removes packages.

## Isolation

| What | Where | Your setup |
| :-- | :-- | :-- |
| Shell | `~/.minflair/quickshell`, started as `qs -p ~/.minflair/quickshell` | `~/.config/quickshell` and other `qs -c` configs untouched |
| Hyprland config | `~/.minflair/hypr`, started with `Hyprland --config` | `~/.config/hypr` untouched |
| `qs` in the session | `~/.minflair/bin/qs` first in `PATH`, only inside the Minflair session | `qs` is unchanged in your other sessions |
| GTK / Qt theme | `~/.minflair/xdg` | `~/.config/gtk-*`, `qt*ct` and gsettings untouched |
| Session entry | `~/.minflair/bin/minflair-session` | your other session entries stay |

`Super+R` restarts only the Minflair shell (`qs kill; qs`). Settings the shell saves, such as the monitor scale, the
cursor and keyboard layout, are written to `~/.minflair/hypr`. The shell also keeps its preferences in
`~/.cache/quickshell/settings_prefs.json`.

## Session

The installer adds `/usr/share/wayland-sessions/minflair.desktop`, so **Minflair** shows in SDDM, GDM, greetd, ly and
other display managers instead of "Hyprland". It runs `~/.minflair/bin/minflair-session`, which puts
`~/.minflair/bin` first in `PATH` and starts Hyprland with `~/.minflair/hypr/hyprland.lua`.

| | |
| :-- | :-- |
| Log | `~/.local/state/minflair/session.log` |
| From a TTY | `~/.minflair/bin/minflair-session` |
| `XDG_SESSION_DESKTOP` | `Minflair` |
| `XDG_CURRENT_DESKTOP` | `Hyprland`, so portals pick the Hyprland backend |
| Extra variables | `~/.minflair/session.env` |

## Hyprland config

`hyprland.lua` loads `animations`, `autostart`, `envs`, `keybinds`, `monitors`, `userprefs` and `windowrules`.
`local.lua` holds what the installer asked for. Autostart skips anything that is not installed.

| File | Holds |
| :-- | :-- |
| `local.lua` | terminal, floating terminal command, file manager, keyboard layout |
| `keybinds.lua` | every bind; the shell's keybinds cheat sheet (`Super+K`) reads it |
| `autostart.lua` | idle daemon, clipboard history, keyring, polkit agent, wallpaper, the shell |
| `envs.lua` | environment, cursor, the GTK/Qt theme overlay |
| `monitors.lua`, `userprefs.lua` | monitor scale, input and general options |
| `windowrules.lua`, `animations.lua` | window rules and animations |
| `scripts/` | volume, brightness, media, touchpad, lock-key and polkit helpers |

## Keybinds

`Super` is the logo key. `Super+K` shows them in the shell.

**Apps and tools**

| Key | Action |
| :-- | :-- |
| `Super+Return` / `Super+Shift+Return` | terminal / floating terminal |
| `Super+E` / `Super+B` | file manager / browser |
| `Super+Shift+C` | colour picker |
| `Super+Space` | switch keyboard layout |
| `Super+R` | restart the shell |
| `Super+Ctrl+T` | toggle touchpad |

**Shell**

| Key | Action |
| :-- | :-- |
| `Super+A` | launcher |
| `Ctrl+Alt+S` or `Super+Shift+A` | control center |
| `Ctrl+Alt+D` or `Super+Shift+D` | dashboard |
| `Ctrl+Alt+M` | music |
| `Ctrl+Alt+N` / `Ctrl+Alt+C` | notifications / calendar |
| `Ctrl+Alt+F` or `Super+Shift+U` | system usage |
| `Ctrl+Alt+T` | pomodoro |
| `Ctrl+Alt+W` or `Super+Shift+W` | wallpaper selector |
| `Ctrl+Alt+X` or `Super+Shift+X` | power menu |
| `Super+V` | clipboard history |
| `Super+Shift+S` | screenshot / recording |
| `Super+S` / `Super+Ctrl+S` | Minflair settings / shell settings |
| `Super+L` | lock screen |

**Windows**

| Key | Action |
| :-- | :-- |
| `Super+Q` | close |
| `Super+W` | toggle floating |
| `Super+F` / `Super+Shift+F` | maximize / fullscreen |
| `Super+J` / `Super+P` | toggle split / pseudo-tile |
| `Super+C` / `Super+Shift+P` | center floating / pin |
| `Super+N` / `Super+Shift+N` | minimize / restore minimized |
| `Super+G` / `Super+Tab` / `Super+Shift+G` | group / cycle group / lock group |
| `Super+Shift+M` | exit Hyprland |

**Navigation**

| Key | Action |
| :-- | :-- |
| `Super+Arrows` | focus |
| `Super+Shift+Arrows` | move window |
| `Super+Alt+Arrows` | resize |
| `Super+Alt+Shift+Arrows` | swap |
| `Super+1..0` / `Super+Shift+1..0` | workspace / send window there |
| `Super+Ctrl+Left/Right`, `Super+Scroll` | previous / next workspace |
| `Super+Mouse left/right drag` | move / resize window |

**Bar style**

| Key | Action |
| :-- | :-- |
| `Super+Alt+B` / `Super+Alt+Shift+B` | next / previous style |
| `Super+Alt+1` ... `3` | Convex / Island / Side |

Media, volume, brightness, mic-mute, touchpad and Caps/Num-lock keys work with an on-screen display. The panels are
toggled through sockets, so any other keybinding tool can use `socat - UNIX-CONNECT:/tmp/quickshell_<panel>` with
`launcher`, `clipboard`, `wallpaper`, `powerMenu`, `controlCenter`, `dashboard`, `notificationsCenter`, `calendar`,
`music`, `systemUsage` or `screenshot`. The style command is `qs ipc call bar cycle|prev|get|set <convex|island|side>`.

## Side

A solid frame around the screen, thick on the bar's edge, with panels that grow out of it. It has its own palette
(AMOLED by default; Mode in Shell settings switches to Dark, Light or follow-theme), the Caelestia dashboard,
launcher, power panel, Wi-Fi / Bluetooth / sound popouts and the shell settings.

| Part | Details |
| :-- | :-- |
| Edge | left, right, top or bottom (Settings > Bar > Position) |
| Panels | power panel on the right edge, dashboard on the top, launcher (off by default) on the bottom; Wi-Fi, Bluetooth, sound, calendar and notifications from their bar icons; wallpaper and screenshot drop from the top |
| Space | the frame reserves its thickness |

### Dynamic bar

Off by default. It shrinks the bar to a small capsule and grows it back on demand.

| | Behaviour |
| :-- | :-- |
| Resting state | small capsule: workspaces, clock, the song (while a player runs) |
| Grow | hover, or click when "Expand on hover" is off |
| Shrink | when the pointer leaves |
| Song | hover or click opens a compact player (cover, title, seek bar, previous, play, next) out of the bar's edge, centred on the song |

| Setting (Settings > Bar > Dynamic bar) | Effect |
| :-- | :-- |
| Dynamic bar | shrink the bar to a capsule |
| Expand on hover | off: click the capsule to expand |
| Music card on hover | hover the song to open the player; click always works |
| Keep expanded | always show the whole bar |

### Bar entries

Each can be turned off in Settings > Bar.

| Entry | Shows |
| :-- | :-- |
| Launcher | opens the launcher |
| Workspaces | Caelestia's switcher: small circles for empty, rounded squares for occupied, a polygon that changes shape for the active one; numbers and app-icon styles in settings |
| Active window | title of the focused window |
| Tray | tray icons |
| Status | network, Bluetooth, volume, brightness, keyboard layout, lock keys, notifications |
| Clock | date and time; click opens the calendar |
| Power | hover or click opens the power panel |

Scrolling the first half of the bar changes volume, the second half brightness, and scrolling the workspaces switches
workspace.

### Dashboard

Tabs: Dashboard, Media, Performance, Weather. Left/Right, Tab and Home/End switch, Escape closes.

| Part | Details |
| :-- | :-- |
| User card | round avatar filled from your logo image, then `~/.face`, then the distro logo, then your initial; the OS row reads the brand from `/etc/issue` and `os-release` ("OS name" in settings overrides it) |
| Media | cookie-shaped cover that turns while playing with an audio-reactive ring (needs `cava`), title, artist, album, wavy seek bar, shuffle / previous / play / next / repeat, synced lyrics from lrclib.net, a player selector; follows whatever is playing when no player is chosen |
| Performance | usage gauges for the system |
| Weather | forecast for the city set in Panels, or located by IP |

### Wallpapers

`~/Pictures/Wallpapers` and `/usr/share/backgrounds`, subfolders included; the folder list is editable in settings.
Arrow keys browse, Enter sets.

## Shell settings (`Super+Ctrl+S`)

| Page | Covers |
| :-- | :-- |
| Bar | position, workspaces, dashboard logo and OS name, dynamic bar, entries, scrolling, hover popouts |
| Frame & Style | mode, frame, border, rounding |
| App Appearance | GTK theme, app font and size, icon theme, cursor theme and size |
| Wallpapers | wallpaper folders, random wallpaper |
| Panels | hover panels, dashboard, weather |
| GitHub, Shortcuts | account widget, keybinds |

**App Appearance** is written to `~/.minflair` only. Apps started from the launcher or the Minflair session pick it
up; apps already running keep their old look until restarted. The shell font is separate from the app font.

## Packages

`./install.sh --check` lists what is missing.

| Group | Packages |
| :-- | :-- |
| Core | `hyprland` `quickshell` `hypridle` `hyprpolkitagent` `hyprpicker` `xdg-desktop-portal-hyprland` `xdg-desktop-portal-gtk` `qt6-wayland` |
| Shell | `python` `python-pillow` `socat` `wl-clipboard` `cliphist` `brightnessctl` `playerctl` `swaybg` `grim` `slurp` `imagemagick` `libnotify` |
| System | `networkmanager` `network-manager-applet` `bluez` `bluez-utils` `pipewire` `pipewire-pulse` `pipewire-alsa` `wireplumber` `gnome-keyring` |
| Look | `ttf-inter` `adw-gtk-theme` `qt6ct` `cava` `zenity` |
| Your choice | terminal (`foot` `kitty` `alacritty` `wezterm`), file manager (`nautilus` `thunar` `dolphin`) |

Quickshell must be 0.3 or newer; if the repository version is older use `quickshell-git` from the AUR.

## Troubleshooting

| Symptom | What to do |
| :-- | :-- |
| Nothing loads | in a terminal run `~/.minflair/bin/qs` and read the errors; `~/.minflair/bin/qs log` shows the last run |
| Session does not start | read `~/.local/state/minflair/session.log` |
| Keys do nothing in the launcher, wallpaper selector or screenshot panel | right after opening the launcher run `~/.minflair/bin/qs log \| grep "side overlay focus"` and send the output |
| Minflair is missing from the display manager | run `./install.sh --session --no-packages --no-shell --no-hypr` |
| Package updates | detected for pacman, AUR (paru/yay), apt and dnf |
