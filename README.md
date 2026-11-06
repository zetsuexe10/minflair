# Minflair

A Quickshell shell and a Hyprland (Lua) config for **Arch Linux** and **Debian 13 (trixie)**. One installer puts
everything in `~/.minflair`, so your own `~/.config/hypr`, `~/.config/quickshell` and other dotfiles are never read,
replaced or changed, and your other desktops keep running as they are.

| # | Bar | What it is | Switch |
| :-: | :-- | :-- | :-- |
| 1 | Convex | the original top bar with a curved centre | `Super+Alt+1` |
| 2 | Island | a floating island at the top centre; widgets expand out of it | `Super+Alt+2` |
| 3 | Side | a frame around the screen with the bar on one edge; panels grow out of it; can shrink to a small capsule | `Super+Alt+3` |
| 4 | Dynamic | a compact pill with the clock, now playing and notifications; widgets morph out of it | `Super+Alt+4` |

`Super+Alt+B` cycles the bars, `Super+Alt+Shift+B` goes back, or use Settings > Bar. The default is Island.

**Contents:** [Install](#install) · [Update and uninstall](#update-and-uninstall) · [Isolation](#isolation) ·
[Session](#session) · [Hyprland config](#hyprland-config) · [Keybinds](#keybinds) · [Bars](#bars) ·
[Dashboard](#dashboard) · [Settings](#settings) · [Packages](#packages) · [Login screen](#login-screen) ·
[Troubleshooting](#troubleshooting)

## Install

Requirements: Arch Linux or Debian 13, `git`, `sudo`, and a normal user (not root). Run it from a terminal.

**One command** (downloads the repository to `~/.minflair/src` and starts the installer):

```sh
curl -fsSL https://raw.githubusercontent.com/zetsuexe10/minflair/minflair/install.sh | bash
```

Pass options after `-s --`:

```sh
curl -fsSL https://raw.githubusercontent.com/zetsuexe10/minflair/minflair/install.sh | bash -s -- --yes --style side
```

**Or clone it yourself:**

```sh
git clone -b minflair https://github.com/zetsuexe10/minflair ~/minflair
cd ~/minflair
./install.sh
```

When it finishes, log out and choose **Minflair** in your login screen, or start it from a TTY with
`~/.minflair/bin/minflair-session`.

The installer asks before each step and takes the bracketed default on Enter. `--yes` answers yes to everything.

| Option | Effect |
| :-- | :-- |
| `-y`, `--yes` | answer yes to everything and use the defaults |
| `--style convex\|island\|side\|dynamic` | starting bar |
| `--terminal foot\|kitty\|alacritty\|wezterm` | terminal for `Super+Return` |
| `--files nautilus\|thunar\|dolphin` | file manager for `Super+E` |
| `--layout us,es` | keyboard layouts |
| `--no-packages`, `--no-shell`, `--no-hypr`, `--no-session`, `--no-services` | skip a step |
| `--aur-helper paru\|yay` | Arch only: helper for packages that are not in the repositories |
| `--greeter` | Debian/FlickOS only: also install the greetd login screen |
| `--check` | report what is installed and what is missing, change nothing |

```sh
./install.sh --yes --style side --terminal kitty --files thunar --layout us,es
```

| Step | What it does |
| :-- | :-- |
| Packages | Arch: pacman, plus an AUR helper for the rest. Debian: apt, with Hyprland and Quickshell from `trixie-backports` (enabled if missing). Requires Hyprland 0.55+ and Quickshell 0.3+ |
| Shell | copies `config/quickshell` to `~/.minflair/quickshell` and sets the starting bar |
| Hyprland | copies `config/hypr` to `~/.minflair/hypr` and writes your choices to `~/.minflair/hypr/local.lua` |
| Launchers | `~/.minflair/bin/qs` and `~/.minflair/bin/minflair-session` |
| Session | adds **Minflair** to `/usr/share/wayland-sessions` (sudo) |
| Services | enables NetworkManager and Bluetooth (sudo) |

Environment variables for the one-command install: `MINFLAIR_REF` (branch, default `minflair`), `MINFLAIR_SRC`
(where the repository is downloaded, default `~/.minflair/src`), `MINFLAIR_HOME` (install location, default
`~/.minflair`).

## Update and uninstall

| Task | Command |
| :-- | :-- |
| Update | run the one-command install again, or `git pull && ./install.sh --no-packages` in your clone |
| Uninstall | `./uninstall.sh` (or `~/.minflair/src/uninstall.sh`); `--keep-data` keeps theme output and backups |

Reinstalling moves the previous `~/.minflair/quickshell` and `~/.minflair/hypr` to `~/.minflair/backup/<date>`.
The uninstaller removes the session entry and `~/.minflair`. It never touches `~/.config` and never removes packages.

## Isolation

| What | Where | Your setup |
| :-- | :-- | :-- |
| Shell | `~/.minflair/quickshell`, started as `qs -p ~/.minflair/quickshell` | `~/.config/quickshell` and other `qs -c` configs untouched |
| Hyprland config | `~/.minflair/hypr`, started with `Hyprland --config` | `~/.config/hypr` untouched |
| `qs` in the session | `~/.minflair/bin/qs` first in `PATH`, only inside the Minflair session | `qs` is unchanged in your other sessions |
| GTK / Qt theme | `~/.minflair/xdg` | `~/.config/gtk-*`, `qt*ct` and gsettings untouched |
| Session entry | `~/.minflair/bin/minflair-session` | your other session entries stay |

`Super+R` restarts only the Minflair shell. Settings you change in the shell, such as the GTK theme, cursor, icons,
fonts, monitor scale and keyboard layout, are saved under `~/.minflair` and restored on the next start. The shell keeps
its other preferences in `~/.cache/quickshell/settings_prefs.json`.

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
Autostart skips anything that is not installed.

| File | Holds |
| :-- | :-- |
| `local.lua` | terminal, floating terminal command, file manager, keyboard layout |
| `keybinds.lua` | every bind; the keybinds cheat sheet (`Super+K`) reads it |
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
| `Super+Shift+I` | GitHub widget |
| `Ctrl+Alt+M` | music |
| `Ctrl+Alt+N` / `Ctrl+Alt+C` | notifications / calendar |
| `Ctrl+Alt+F` or `Super+Shift+U` | system usage |
| `Ctrl+Alt+T` | pomodoro |
| `Ctrl+Alt+W` or `Super+Shift+W` | wallpaper selector |
| `Ctrl+Alt+X` or `Super+Shift+X` | power menu |
| `Super+X` | power menu (Dynamic bar) |
| `Super+V` | clipboard history |
| `Super+Shift+S` | screenshot / recording |
| `Super+S` / `Super+Ctrl+S` | settings / settings on the Bar page |
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

**Bars**

| Key | Action |
| :-- | :-- |
| `Super+Alt+B` / `Super+Alt+Shift+B` | next / previous bar |
| `Super+Alt+1` ... `4` | Convex / Island / Side / Dynamic |

Media, volume, brightness, mic-mute, touchpad and Caps/Num-lock keys work with an on-screen display. Panels toggle
through sockets, so any keybinding tool can use `socat - UNIX-CONNECT:/tmp/quickshell_<panel>` with `launcher`,
`clipboard`, `wallpaper`, `powerMenu`, `controlCenter`, `dashboard`, `github`, `notificationsCenter`, `calendar`,
`music`, `systemUsage` or `screenshot`. Other commands:

| Command | Effect |
| :-- | :-- |
| `qs ipc call bar cycle\|prev\|get` | next, previous, or print the current bar |
| `qs ipc call bar set <convex\|island\|side\|dynamic>` | switch bar |
| `qs ipc call settings open <page>` | open Settings on a page (`bar`, `side`, `dynamic`, `profile`, ...) |

## Bars

### Convex and Island

Convex is the classic curved top bar: workspaces and the focused window on the left, the clock pill in the centre,
network and status icons on the right. Island floats at the top centre and grows when a widget opens (media, launcher,
wallpaper, dashboard), then shrinks back. Settings > Island can collapse it to a single pill, choose what the right
circle shows and show or hide workspaces and the tray.

### Side

A solid frame around the screen, thick on the bar's edge, with panels that grow out of it. It has its own palette
(AMOLED by default; Mode under Settings > Side · Frame switches to Dark, Light or follow-theme), the Caelestia
dashboard, launcher, power panel and Wi-Fi / Bluetooth / sound popouts.

| Part | Details |
| :-- | :-- |
| Edge | left, right, top or bottom (Settings > Side) |
| Panels | power panel on the right edge, dashboard on the top, launcher (off by default) on the bottom; Wi-Fi, Bluetooth, sound, calendar and notifications from their bar icons; wallpaper and screenshot drop from the top |
| Space | the frame reserves its thickness |
| Scrolling | first half of the bar changes volume, second half brightness, over the workspaces switches workspace |

**Entries.** Each can be turned off in Settings > Side.

| Entry | Shows |
| :-- | :-- |
| Launcher | opens the launcher |
| Workspaces | small circles for empty, rounded squares for occupied, a polygon for the active one; numbers and app-icon styles also available |
| Active window | title of the focused window |
| Tray | tray icons |
| Status | network, Bluetooth, volume, brightness, keyboard layout, lock keys, notifications |
| Clock | date and time; click opens the calendar |
| Now playing | the song with its cover (only while a player runs), in the middle of the bar; hover or click opens the player |
| Power | hover or click opens the power panel |

**Layout.** Settings > Side · Layout puts every entry in the **Start**, **Centre** or **End** part of the bar and sets
its order inside that part (lowest first). The centre part is centred on the screen edge, so the song stays in the
middle.

| Entry | Default part | Default order |
| :-- | :-- | :-: |
| Launcher button | Start | 1 |
| Workspaces | Start | 2 |
| Active window | Start | 3 |
| Now playing | Centre | 1 |
| System tray | End | 1 |
| Status icons | End | 2 |
| Clock | End | 3 |
| Power button | End | 4 |

**Dynamic mode.** Off by default. The bar shrinks to a small capsule and grows back on demand.

| | Behaviour |
| :-- | :-- |
| Resting state | capsule with workspaces, the song in the middle (while a player runs) and the clock |
| Grow | hover, or click when "Expand on hover" is off |
| Shrink | when the pointer leaves |
| Song | hover or click opens a compact player (cover, title, seek bar, previous, play, next) out of the bar, centred on the song |

| Setting (Settings > Side > Dynamic mode) | Effect |
| :-- | :-- |
| Dynamic bar | shrink the bar to a capsule |
| Expand on hover | off: click the capsule to expand |
| Keep expanded | always show the whole bar |
| Music card on hover | hover the song to open the player; click always works |

### Dynamic

A floating pill at the top centre. Scroll or drag it to switch between the clock, now playing and notifications; hover
to peek at the song. Workspaces sit in their own chip on the left and a round music button on the right opens the
player. The wallpaper picker, screenshot, clipboard, power, launcher, dashboard and GitHub widgets open inside the
island, and arrow keys browse the wallpaper list.

| Setting (Settings > Dynamic) | Effect |
| :-- | :-- |
| Music button | round button beside the pill |
| Hover peek | hover shows the song |
| Swipe and scroll | scroll or drag the pill to change view |
| Reserve space | tiled windows stop below the pill |
| Idle view | what the pill returns to: automatic, time, music or notifications |
| Views | clock, workspaces, music, notifications |
| Screen frame | optional border like the Side bar; thickness, rounding and colours come from Side |

## Dashboard

Tabs: Dashboard, Media, Performance, Weather. Left/Right, Tab and Home/End switch, Escape closes.

| Part | Details |
| :-- | :-- |
| User card | round avatar from your logo image, then `~/.face`, then the distro logo, then your initial; the OS row reads the brand from `/etc/issue` and `os-release` ("OS name" in Settings > Panels overrides it) |
| Media | cover that turns while playing with an audio-reactive ring (needs `cava`), title, artist, album, seek bar, shuffle / previous / play / next / repeat, synced lyrics from lrclib.net, a player selector |
| Performance | usage gauges for the system |
| Weather | forecast for the city set in Panels, or located by IP |

Wallpapers come from `~/Pictures/Wallpapers` and `/usr/share/backgrounds`, subfolders included; the folder list is
editable in Settings > Wallpaper. Arrow keys browse, Enter sets.

## Settings

`Super+S` opens one window with a search box and a grouped sidebar. Each bar has its own page.

| Section | Pages |
| :-- | :-- |
| Profile | account, host, distro and the picture used by the lock screen |
| Desktop | Appearance, Wallpaper, Bar (active bar, clock and workspaces shared by every bar), Panels (dashboard, weather), Visual Effects, Windows & Display |
| Bars | Convex, Island, Side (with Side · Layout and Side · Frame), Dynamic; reset buttons on Side · Layout and Dynamic |
| Input & hardware | Mouse & Touchpad, Keyboard & Clipboard |
| System | App Appearance, Integrations & Apps (default apps, GitHub account, token and overview) |
| About | Shortcuts, About System |

**App Appearance** (GTK theme, app font and size, icon theme, cursor theme and size) is written to `~/.minflair` only
and restored on every start. Apps started from the launcher or the Minflair session pick it up; apps already running
keep their old look until restarted. The shell font is separate from the app font. The GitHub token is passed to the
fetch scripts through the environment, never on a command line.

## Packages

`./install.sh --check` lists what is missing. Quickshell must be 0.3 or newer; on Arch use `quickshell-git` from the AUR
if the repository version is older.

| Group | Arch | Debian 13 |
| :-- | :-- | :-- |
| Core | `hyprland` `quickshell` `hypridle` `hyprpolkitagent` `hyprpicker` `xdg-desktop-portal-hyprland` `xdg-desktop-portal-gtk` `qt6-wayland` | the same plus `hyprlock` `hyprsunset`; Hyprland and Quickshell from `trixie-backports` |
| Shell | `python` `python-pillow` `python-gobject` `socat` `jq` `wl-clipboard` `cliphist` `brightnessctl` `playerctl` `swaybg` `grim` `slurp` `wf-recorder` `tesseract` `imagemagick` `libnotify` | `python3` `python3-gi` `python3-pam` `python3-pil` and the same tools (`libnotify-bin`, `tesseract-ocr`) |
| System | `networkmanager` `network-manager-applet` `bluez` `power-profiles-daemon` `upower` `pipewire` `wireplumber` `gnome-keyring` | `network-manager` `network-manager-gnome` and the same |
| Look | `ttf-inter` `adw-gtk-theme` `qt6ct` `cava` `zenity` `papirus-icon-theme` `noto-fonts` | `fonts-inter` `adw-gtk3` `qt6ct` `cava` `zenity` `papirus-icon-theme` `fonts-noto-*` |
| Your choice | terminal (`foot` `kitty` `alacritty` `wezterm`), file manager (`nautilus` `thunar` `dolphin`) | same |

The cursor theme `Vimix-cursors` is optional and not packaged on Debian
(`git clone https://github.com/vinceliuice/Vimix-cursors && cd Vimix-cursors && ./install.sh`); Adwaita is used until
then.

## Login screen

Debian/FlickOS only, optional. `./install.sh --greeter` (or `sudo tools/install-greeter.sh`) installs a Quickshell
greeter on greetd inside cage: user, password and a session picker with readable names from
`/usr/share/wayland-sessions`. Colours and the blurred wallpaper follow the shell. `sudo tools/install-greeter.sh
--revert` restores the original greeter. Log: `/var/tmp/minflair-greeter/greeter.log`. Layout and icons are adapted
from the Archcraft SDDM theme (GPLv3, see `greeter/assets/NOTICE`). On other display managers (SDDM, GDM, ly) the
**Minflair** session entry is enough.

## Troubleshooting

| Symptom | What to do |
| :-- | :-- |
| Nothing loads | run `./tools/doctor.sh` inside the session and send the output; or run `~/.minflair/bin/qs` in a terminal and read the errors; `~/.minflair/bin/qs log` shows the last run |
| QML errors after an edit | `./tools/smoke-test.sh config/quickshell` loads the shell offscreen and reports load errors |
| Session does not start | read `~/.local/state/minflair/session.log` |
| Minflair does not show in SDDM | the session file must not contain `TryExec`; run `./install.sh --session --no-packages --no-shell --no-hypr`, then `sudo systemctl restart sddm` |
| Keys do nothing in the launcher, wallpaper selector or screenshot panel | right after opening the launcher run `~/.minflair/bin/qs log \| grep "side overlay focus"` and send the output |
| Theme, cursor or font did not change | apps already running keep the old look until restarted; check Settings > App Appearance > Status says "Active" |
| One-command install fails to download | check that `git` is installed and `https://github.com` is reachable, then run it again |
| Package updates | detected for pacman, AUR (paru/yay), apt and dnf |

## License

See `LICENSE`.
