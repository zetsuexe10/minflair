#!/usr/bin/env bash
set -u

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOME_DIR="${MINFLAIR_HOME:-$HOME/.minflair}"
CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}"
SESSION_FILE="/usr/share/wayland-sessions/minflair.desktop"
BACKUP="$HOME_DIR/backup/$(date +%Y%m%d-%H%M%S)"

YES=0
DO_PACKAGES=ask
DO_SHELL=ask
DO_HYPR=ask
DO_SESSION=ask
DO_SERVICES=ask
CHECK=0
STYLE=""
TERMINAL=""
FILES=""
LAYOUT=""
AUR_HELPER=""

if [ -t 1 ]; then
  B=$'\033[1m'; G=$'\033[32m'; Y=$'\033[33m'; R=$'\033[31m'; D=$'\033[2m'; N=$'\033[0m'
else
  B=""; G=""; Y=""; R=""; D=""; N=""
fi

say() { printf '%s\n' "$*"; }
step() { printf '\n%s==>%s %s%s%s\n' "$G" "$N" "$B" "$*" "$N"; }
warn() { printf '%swarning:%s %s\n' "$Y" "$N" "$*" >&2; }
die() { printf '%serror:%s %s\n' "$R" "$N" "$*" >&2; exit 1; }

usage() {
  cat <<U
Minflair installer for Arch Linux

usage: ./install.sh [options]

  -y, --yes               answer yes to every question and use the defaults
      --check             only report what is installed and what is missing
      --packages          install packages without asking
      --no-packages       skip package installation
      --shell             install the Quickshell config without asking
      --no-shell          skip the Quickshell config
      --hypr              install the Hyprland config without asking
      --no-hypr           skip the Hyprland config
      --session           install the Minflair login session without asking
      --no-session        skip the login session
      --services          enable NetworkManager and Bluetooth without asking
      --no-services       do not touch services
      --style <name>      bar style: island, side or pill
      --terminal <name>   terminal: foot, kitty, alacritty or wezterm
      --files <name>      file manager: nautilus, thunar or dolphin
      --layout <code>     keyboard layout, for example us or us,es
      --aur-helper <cmd>  paru or yay, used for packages missing from the repos
  -h, --help              show this help

Without --yes every step is a question; pressing enter takes the default shown in brackets.
When stdin is not a terminal the defaults are used.
U
}

need_value() { [ $# -ge 2 ] || die "$1 needs a value"; }

while [ $# -gt 0 ]; do
  case "$1" in
    -y|--yes) YES=1 ;;
    --check) CHECK=1 ;;
    --packages) DO_PACKAGES=yes ;;
    --no-packages) DO_PACKAGES=no ;;
    --shell) DO_SHELL=yes ;;
    --no-shell) DO_SHELL=no ;;
    --hypr) DO_HYPR=yes ;;
    --no-hypr) DO_HYPR=no ;;
    --session) DO_SESSION=yes ;;
    --no-session) DO_SESSION=no ;;
    --services) DO_SERVICES=yes ;;
    --no-services) DO_SERVICES=no ;;
    --style) need_value "$@"; STYLE="$2"; shift ;;
    --terminal) need_value "$@"; TERMINAL="$2"; shift ;;
    --files) need_value "$@"; FILES="$2"; shift ;;
    --layout) need_value "$@"; LAYOUT="$2"; shift ;;
    --aur-helper) need_value "$@"; AUR_HELPER="$2"; shift ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; die "unknown option: $1" ;;
  esac
  shift
done

INTERACTIVE=0
if [ "$YES" -eq 0 ] && [ -t 0 ]; then INTERACTIVE=1; fi

confirm() {
  local prompt="$1" default="${2:-y}" reply hint="[Y/n]"
  [ "$default" = "n" ] && hint="[y/N]"
  if [ "$INTERACTIVE" -eq 0 ]; then
    [ "$default" = "y" ]
    return
  fi
  read -r -p "$prompt $hint " reply || reply=""
  reply="${reply:-$default}"
  case "$reply" in [Yy]*) return 0 ;; *) return 1 ;; esac
}

decide() {
  case "$1" in
    yes) return 0 ;;
    no) return 1 ;;
    *) confirm "$2" "${3:-y}" ;;
  esac
}

choose() {
  local prompt="$1" default="$2"; shift 2
  local options=("$@") reply i
  if [ "$INTERACTIVE" -eq 0 ]; then
    printf '%s' "$default"
    return
  fi
  {
    printf '%s\n' "$prompt"
    for i in "${!options[@]}"; do
      if [ "${options[$i]}" = "$default" ]; then
        printf '  %d) %s %s(default)%s\n' "$((i + 1))" "${options[$i]}" "$D" "$N"
      else
        printf '  %d) %s\n' "$((i + 1))" "${options[$i]}"
      fi
    done
  } >&2
  read -r -p "choice [$default]: " reply || reply=""
  if [ -z "$reply" ]; then
    printf '%s' "$default"
  elif [[ "$reply" =~ ^[0-9]+$ ]] && [ "$reply" -ge 1 ] && [ "$reply" -le "${#options[@]}" ]; then
    printf '%s' "${options[$((reply - 1))]}"
  else
    printf '%s' "$reply"
  fi
}

have() { command -v "$1" >/dev/null 2>&1; }
installed() { pacman -Qq "$1" >/dev/null 2>&1; }

CORE=(hyprland quickshell hypridle hyprpolkitagent hyprpicker xdg-desktop-portal-hyprland xdg-desktop-portal-gtk qt6-wayland)
SHELLDEPS=(python python-pillow socat wl-clipboard cliphist brightnessctl playerctl swaybg grim slurp imagemagick libnotify)
SYSTEM=(networkmanager network-manager-applet bluez bluez-utils pipewire pipewire-pulse pipewire-alsa wireplumber gnome-keyring)
LOOK=(ttf-inter adw-gtk-theme qt6ct cava zenity)

pick_choices() {
  [ -n "$STYLE" ] || STYLE="$(choose "Bar style:" island island side pill)"
  case "$STYLE" in island|side|pill) ;; *) die "unknown bar style: $STYLE (use island, side or pill)" ;; esac

  [ -n "$TERMINAL" ] || TERMINAL="$(choose "Terminal:" foot foot kitty alacritty wezterm)"
  case "$TERMINAL" in foot|kitty|alacritty|wezterm) ;; *) die "unknown terminal: $TERMINAL" ;; esac

  [ -n "$FILES" ] || FILES="$(choose "File manager:" nautilus nautilus thunar dolphin)"
  case "$FILES" in nautilus|thunar|dolphin) ;; *) die "unknown file manager: $FILES" ;; esac

  if [ -z "$LAYOUT" ]; then
    if [ "$INTERACTIVE" -eq 1 ]; then
      read -r -p "Keyboard layout (for example us or us,es) [us]: " LAYOUT || LAYOUT=""
    fi
    LAYOUT="${LAYOUT:-us}"
  fi
  [[ "$LAYOUT" =~ ^[a-z0-9_,:-]+$ ]] || die "invalid keyboard layout: $LAYOUT"
}

terminal_float() {
  case "$1" in
    foot) printf 'foot --app-id terminal-floating' ;;
    kitty) printf 'kitty --class terminal-floating' ;;
    alacritty) printf 'alacritty --class terminal-floating' ;;
    wezterm) printf 'wezterm start --class terminal-floating' ;;
  esac
}

check_status() {
  local missing=0 p
  have pacman || die "pacman not found, this installer is for Arch Linux and derivatives"
  step "Packages"
  for p in "${CORE[@]}" "${SHELLDEPS[@]}" "${SYSTEM[@]}" "${LOOK[@]}" foot nautilus; do
    if installed "$p"; then
      printf '  %sok%s       %s\n' "$G" "$N" "$p"
    else
      printf '  %smissing%s  %s\n' "$R" "$N" "$p"
      missing=$((missing + 1))
    fi
  done
  step "Versions"
  if have Hyprland; then say "  $(Hyprland --version 2>/dev/null | head -n1)"; else say "  Hyprland not installed"; fi
  if have qs; then say "  $(qs --version 2>/dev/null | head -n1)"; else say "  Quickshell not installed"; fi
  step "Minflair"
  if [ -f "$CONFIG/quickshell/shell.qml" ]; then say "  shell config: installed"; else say "  shell config: not installed"; fi
  if [ -f "$CONFIG/hypr/hyprland.lua" ]; then say "  hyprland.lua: installed"; else say "  hyprland.lua: not installed"; fi
  if [ -f "$SESSION_FILE" ]; then say "  session entry: installed"; else say "  session entry: not installed"; fi
  say ""
  say "$missing package(s) missing"
  [ "$missing" -eq 0 ]
}

find_aur_helper() {
  if [ -n "$AUR_HELPER" ]; then
    have "$AUR_HELPER" || die "AUR helper not found: $AUR_HELPER"
    return 0
  fi
  local h
  for h in paru yay; do
    if have "$h"; then AUR_HELPER="$h"; return 0; fi
  done
  return 1
}

install_packages() {
  step "Packages"
  have pacman || die "pacman not found, this installer is for Arch Linux and derivatives"
  have sudo || die "sudo is required to install packages"

  local want=("${CORE[@]}" "${SHELLDEPS[@]}")
  if confirm "Include networking, Bluetooth, PipeWire and keyring packages?" y; then want+=("${SYSTEM[@]}"); fi
  if confirm "Include fonts, GTK/Qt theme helpers and cava?" y; then want+=("${LOOK[@]}"); fi
  want+=("$TERMINAL" "$FILES")

  local repo=() aur=() p
  for p in "${want[@]}"; do
    installed "$p" && continue
    if pacman -Si "$p" >/dev/null 2>&1; then repo+=("$p"); else aur+=("$p"); fi
  done

  if [ "${#repo[@]}" -eq 0 ] && [ "${#aur[@]}" -eq 0 ]; then
    say "everything is already installed"
    return 0
  fi

  if [ "${#repo[@]}" -gt 0 ]; then
    say "from the repositories: ${repo[*]}"
    if confirm "Install them with pacman?" y; then
      local flags=(-S --needed)
      [ "$YES" -eq 1 ] && flags+=(--noconfirm)
      sudo pacman "${flags[@]}" "${repo[@]}" || warn "pacman reported a problem"
    else
      warn "skipped: ${repo[*]}"
    fi
  fi

  if [ "${#aur[@]}" -gt 0 ]; then
    say "not in the official repositories: ${aur[*]}"
    if find_aur_helper; then
      if confirm "Install them from the AUR with $AUR_HELPER?" y; then
        local aflags=(-S --needed)
        [ "$YES" -eq 1 ] && aflags+=(--noconfirm)
        "$AUR_HELPER" "${aflags[@]}" "${aur[@]}" || warn "$AUR_HELPER reported a problem"
      fi
    else
      warn "no AUR helper (paru or yay) found, install these yourself: ${aur[*]}"
    fi
  fi
}

version_ge() { [ "$(printf '%s\n%s\n' "$1" "$2" | sort -V | head -n1)" = "$2" ]; }

check_versions() {
  step "Version check"
  local v
  if have Hyprland; then
    v="$(Hyprland --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -n1)"
    if [ -z "$v" ]; then
      warn "could not read the Hyprland version"
    elif version_ge "$v" 0.55; then
      say "Hyprland $v (Lua config supported)"
    else
      warn "Hyprland $v is older than 0.55, the Lua config will not load: sudo pacman -Syu hyprland"
    fi
  else
    warn "Hyprland is not installed"
  fi
  if have qs; then
    v="$(qs --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -n1)"
    if [ -z "$v" ]; then
      warn "could not read the Quickshell version"
    elif version_ge "$v" 0.3; then
      say "Quickshell $v"
    else
      warn "Quickshell $v is older than 0.3, install quickshell-git from the AUR"
    fi
  else
    warn "Quickshell is not installed"
  fi
}

backup() {
  local target="$1"
  { [ -e "$target" ] || [ -L "$target" ]; } || return 0
  mkdir -p "$BACKUP"
  mv "$target" "$BACKUP/$(basename "$target")"
  say "backed up $target to $BACKUP/"
}

install_shell() {
  step "Quickshell config"
  mkdir -p "$CONFIG"
  backup "$CONFIG/quickshell"
  cp -r "$SRC/config/quickshell" "$CONFIG/quickshell"
  find "$CONFIG/quickshell" -name '*.sh' -exec chmod +x {} +
  say "installed to $CONFIG/quickshell"

  local cache="${XDG_CACHE_HOME:-$HOME/.cache}/quickshell"
  mkdir -p "$cache"
  python3 - "$cache/settings_prefs.json" "$STYLE" <<'P'
import json, sys
path, style = sys.argv[1], sys.argv[2]
try:
    data = json.load(open(path))
except Exception:
    data = {}
data["barStyle"] = style
json.dump(data, open(path, "w"), indent=2)
P
  say "bar style: $STYLE"
}

install_hypr() {
  step "Hyprland config"
  mkdir -p "$CONFIG"
  backup "$CONFIG/hypr"
  cp -r "$SRC/config/hypr" "$CONFIG/hypr"
  find "$CONFIG/hypr/scripts" -name '*.sh' -exec chmod +x {} +

  cat > "$CONFIG/hypr/local.lua" <<L
return {
	terminal = "$TERMINAL",
	terminal_float = "$(terminal_float "$TERMINAL")",
	file_manager = "$FILES",
	kb_layout = "$LAYOUT",
}
L
  say "installed to $CONFIG/hypr"
  say "terminal $TERMINAL, files $FILES, layout $LAYOUT (change them in $CONFIG/hypr/local.lua)"

  mkdir -p "$HOME/Pictures/Wallpapers"
  if [ -z "$(find "$HOME/Pictures/Wallpapers" -maxdepth 1 -type f 2>/dev/null | head -n1)" ]; then
    say "put wallpapers in ~/Pictures/Wallpapers, the wallpaper picker reads that folder"
  fi
}

install_session() {
  step "Minflair session"
  mkdir -p "$HOME_DIR/bin"
  install -m 755 "$SRC/bin/minflair-session" "$HOME_DIR/bin/minflair-session"

  local tmp
  tmp="$(mktemp)"
  cat > "$tmp" <<D
[Desktop Entry]
Name=Minflair
Comment=Hyprland with the Minflair shell
Exec=$HOME_DIR/bin/minflair-session
TryExec=$HOME_DIR/bin/minflair-session
Type=Application
DesktopNames=Hyprland
D
  if have sudo && sudo install -Dm644 "$tmp" "$SESSION_FILE"; then
    say "session entry installed: choose Minflair in your display manager"
  else
    warn "could not write $SESSION_FILE, start from a TTY with: $HOME_DIR/bin/minflair-session"
  fi
  rm -f "$tmp"
}

enable_services() {
  step "Services"
  have systemctl || return 0
  local s
  for s in NetworkManager bluetooth; do
    if systemctl cat "$s.service" >/dev/null 2>&1; then
      if sudo systemctl enable --now "$s.service" >/dev/null 2>&1; then say "enabled $s"; else warn "could not enable $s"; fi
    fi
  done
  systemctl --user enable --now pipewire.socket pipewire-pulse.socket wireplumber.service >/dev/null 2>&1 || true
}

main() {
  [ "$(id -u)" -ne 0 ] || die "do not run this as root, it asks for sudo when it needs it"
  [ -d "$SRC/config/quickshell" ] || die "run this from the Minflair repository (config/quickshell not found)"

  if [ "$CHECK" -eq 1 ]; then
    check_status
    exit $?
  fi

  say "${B}Minflair${N} installer"
  if [ "$YES" -eq 1 ]; then say "${D}--yes: every question is answered yes and the defaults are used${N}"; fi

  pick_choices

  if decide "$DO_PACKAGES" "Install packages?" y; then install_packages; fi
  check_versions
  if decide "$DO_SHELL" "Install the Quickshell config to $CONFIG/quickshell?" y; then install_shell; fi
  if decide "$DO_HYPR" "Install the Hyprland config to $CONFIG/hypr (an existing one is backed up)?" y; then install_hypr; fi
  if decide "$DO_SESSION" "Install the Minflair login session (needs sudo)?" y; then install_session; fi
  if decide "$DO_SERVICES" "Enable NetworkManager and Bluetooth (needs sudo)?" y; then enable_services; fi

  step "Done"
  say "Log out and choose ${B}Minflair${N} in your display manager, or run ${B}$HOME_DIR/bin/minflair-session${N} from a TTY."
  say "Backups, if any, are in $HOME_DIR/backup. Check the setup any time with ./install.sh --check"
}

main
