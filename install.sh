#!/usr/bin/env bash
set -u

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOME_DIR="${MINFLAIR_HOME:-$HOME/.minflair}"
SESSION_FILE="/usr/share/wayland-sessions/minflair.desktop"
BACKUP="$HOME_DIR/backup/$(date +%Y%m%d-%H%M%S)"

YES=0
DO_PACKAGES=ask
DO_SHELL=ask
DO_HYPR=ask
DO_SESSION=ask
DO_SERVICES=ask
DO_GREETER=ask
CHECK=0
STYLE=""
TERMINAL=""
FILES=""
LAYOUT=""
AUR_HELPER=""
DISTRO=""

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
Minflair installer for Arch Linux and Debian 13

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
      --greeter           install the greetd login screen (Debian/FlickOS only)
      --no-greeter        skip the login screen
      --style <name>      starting bar style: convex, island, side or dynamic
      --terminal <name>   terminal: foot, kitty, alacritty or wezterm
      --files <name>      file manager: nautilus, thunar or dolphin
      --layout <code>     keyboard layout, for example us or us,es
      --aur-helper <cmd>  paru or yay, used for Arch packages missing from the repos
  -h, --help              show this help

Everything is installed into ~/.minflair; your ~/.config is never touched.
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
    --greeter) DO_GREETER=yes ;;
    --no-greeter) DO_GREETER=no ;;
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

detect_distro() {
  if have pacman; then
    DISTRO=arch
  elif have apt-get; then
    DISTRO=debian
  else
    die "neither pacman nor apt-get found: this installer supports Arch Linux and Debian 13"
  fi
}

installed() {
  case "$DISTRO" in
    arch) pacman -Qq "$1" >/dev/null 2>&1 ;;
    debian) dpkg -s "$1" >/dev/null 2>&1 ;;
  esac
}

load_packages() {
  case "$DISTRO" in
    arch)
      PKG_CORE=(hyprland quickshell hypridle hyprpolkitagent hyprpicker xdg-desktop-portal-hyprland xdg-desktop-portal-gtk qt6-wayland)
      PKG_SHELL=(python python-pillow python-gobject socat jq wl-clipboard cliphist brightnessctl playerctl swaybg grim slurp wf-recorder tesseract tesseract-data-eng imagemagick libnotify xdg-utils)
      PKG_SYSTEM=(networkmanager network-manager-applet bluez bluez-utils power-profiles-daemon upower pipewire pipewire-pulse pipewire-alsa wireplumber gnome-keyring)
      PKG_LOOK=(ttf-inter adw-gtk-theme qt6ct cava zenity papirus-icon-theme noto-fonts noto-fonts-emoji)
      ;;
    debian)
      PKG_CORE=(quickshell hyprland hypridle hyprlock hyprpicker hyprsunset hyprpolkitagent xdg-desktop-portal-hyprland xdg-desktop-portal-gtk qt6-wayland)
      PKG_SHELL=(python3 python3-gi python3-pam python3-pil socat jq wl-clipboard cliphist brightnessctl playerctl swaybg grim slurp wf-recorder tesseract-ocr tesseract-ocr-eng imagemagick libnotify-bin xdg-utils)
      PKG_SYSTEM=(network-manager network-manager-gnome bluez power-profiles-daemon upower pipewire pipewire-pulse wireplumber gnome-keyring)
      PKG_LOOK=(fonts-inter adw-gtk3 qt6ct cava zenity papirus-icon-theme fonts-noto-core fonts-noto-color-emoji)
      ;;
  esac
}

pick_choices() {
  local default_style=island
  [ -n "$STYLE" ] || STYLE="$(choose "Bar style:" "$default_style" convex island side dynamic)"
  case "$STYLE" in convex|island|side|dynamic) ;; *) die "unknown bar style: $STYLE (use convex, island, side or dynamic)" ;; esac

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
  load_packages
  step "Packages ($DISTRO)"
  for p in "${PKG_CORE[@]}" "${PKG_SHELL[@]}" "${PKG_SYSTEM[@]}" "${PKG_LOOK[@]}" foot nautilus; do
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
  if [ -f "$HOME_DIR/quickshell/shell.qml" ]; then say "  shell config: installed in $HOME_DIR/quickshell"; else say "  shell config: not installed"; fi
  if [ -f "$HOME_DIR/hypr/hyprland.lua" ]; then say "  hyprland.lua: installed in $HOME_DIR/hypr"; else say "  hyprland.lua: not installed"; fi
  if [ -x "$HOME_DIR/bin/qs" ]; then say "  qs launcher: installed"; else say "  qs launcher: not installed"; fi
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

select_packages() {
  WANT=("${PKG_CORE[@]}" "${PKG_SHELL[@]}")
  if confirm "Include networking, Bluetooth, PipeWire and keyring packages?" y; then WANT+=("${PKG_SYSTEM[@]}"); fi
  if confirm "Include fonts, GTK/Qt theme helpers and cava?" y; then WANT+=("${PKG_LOOK[@]}"); fi
  WANT+=("$TERMINAL" "$FILES")
}

install_packages_arch() {
  have sudo || die "sudo is required to install packages"
  select_packages
  local repo=() aur=() p
  for p in "${WANT[@]}"; do
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

install_packages_debian() {
  have sudo || die "sudo is required to install packages"
  select_packages
  local codename=""
  [ -r /etc/os-release ] && codename="$(. /etc/os-release; printf '%s' "${VERSION_CODENAME:-}")"
  local use_backports=0
  if [ "$codename" = "trixie" ]; then
    use_backports=1
    if ! grep -rqs "trixie-backports" /etc/apt/sources.list /etc/apt/sources.list.d 2>/dev/null; then
      if confirm "Enable trixie-backports (Hyprland and Quickshell come from there)?" y; then
        printf 'Types: deb\nURIs: http://deb.debian.org/debian\nSuites: trixie-backports\nComponents: main\nSigned-By: /usr/share/keyrings/debian-archive-keyring.gpg\n' \
          | sudo tee /etc/apt/sources.list.d/trixie-backports.sources >/dev/null
      else
        use_backports=0
        warn "without backports Hyprland and Quickshell may be missing"
      fi
    fi
  else
    warn "this is not Debian 13 (trixie); packages come from your enabled repositories"
  fi

  local flags=(install)
  [ "$YES" -eq 1 ] && flags+=(-y)
  sudo apt-get update || warn "apt-get update reported a problem"

  local core=() rest=() p
  for p in "${WANT[@]}"; do
    installed "$p" && continue
    case " ${PKG_CORE[*]} " in
      *" $p "*) case "$p" in xdg-desktop-portal-gtk|qt6-wayland) rest+=("$p") ;; *) core+=("$p") ;; esac ;;
      *) rest+=("$p") ;;
    esac
  done
  if [ "${#rest[@]}" -gt 0 ]; then
    say "from apt: ${rest[*]}"
    sudo apt-get "${flags[@]}" "${rest[@]}" || warn "apt reported a problem"
  fi
  if [ "${#core[@]}" -gt 0 ]; then
    say "Hyprland and Quickshell: ${core[*]}"
    if [ "$use_backports" -eq 1 ]; then
      sudo apt-get "${flags[@]}" -t trixie-backports "${core[@]}" || warn "backports install reported a problem"
    else
      sudo apt-get "${flags[@]}" "${core[@]}" || warn "apt reported a problem"
    fi
  fi
  if ! ls /usr/share/icons/Vimix-cursors >/dev/null 2>&1 && ! ls "$HOME/.local/share/icons/Vimix-cursors" >/dev/null 2>&1; then
    say "optional cursor theme: git clone https://github.com/vinceliuice/Vimix-cursors && cd Vimix-cursors && ./install.sh (Adwaita is used until then)"
  fi
}

install_packages() {
  step "Packages"
  load_packages
  case "$DISTRO" in
    arch) install_packages_arch ;;
    debian) install_packages_debian ;;
  esac
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
      warn "Hyprland $v is older than 0.55, the Lua config will not load; update Hyprland"
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
      warn "Quickshell $v is older than 0.3 (Arch: quickshell-git from the AUR, Debian: trixie-backports)"
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
  mkdir -p "$HOME_DIR/bin"
  backup "$HOME_DIR/quickshell"
  cp -r "$SRC/config/quickshell" "$HOME_DIR/quickshell"
  find "$HOME_DIR/quickshell" \( -name '*.sh' -o -name '*.py' \) -exec chmod +x {} +
  install -m 755 "$SRC/bin/qs" "$HOME_DIR/bin/qs"
  say "installed to $HOME_DIR/quickshell (your ~/.config/quickshell is not touched)"

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
  mkdir -p "$HOME_DIR"
  backup "$HOME_DIR/hypr"
  cp -r "$SRC/config/hypr" "$HOME_DIR/hypr"
  find "$HOME_DIR/hypr/scripts" -name '*.sh' -exec chmod +x {} +

  cat > "$HOME_DIR/hypr/local.lua" <<L
return {
	terminal = "$TERMINAL",
	terminal_float = "$(terminal_float "$TERMINAL")",
	file_manager = "$FILES",
	kb_layout = "$LAYOUT",
}
L
  say "installed to $HOME_DIR/hypr (your ~/.config/hypr is not touched)"
  say "terminal $TERMINAL, files $FILES, layout $LAYOUT (change them in $HOME_DIR/hypr/local.lua)"

  mkdir -p "$HOME/Pictures/Wallpapers"
  if [ -z "$(find "$HOME/Pictures/Wallpapers" -maxdepth 1 -type f 2>/dev/null | head -n1)" ]; then
    say "put wallpapers in ~/Pictures/Wallpapers, the wallpaper picker reads that folder"
  fi
}

install_session() {
  step "Minflair session"
  mkdir -p "$HOME_DIR/bin"
  install -m 755 "$SRC/bin/minflair-session" "$HOME_DIR/bin/minflair-session"
  install -m 755 "$SRC/bin/qs" "$HOME_DIR/bin/qs"

  local tmp
  tmp="$(mktemp)"
  cat > "$tmp" <<D
[Desktop Entry]
Name=Minflair
Comment=Hyprland with the Minflair shell
Exec=$HOME_DIR/bin/minflair-session
Type=Application
D
  if have sudo && sudo install -Dm644 "$tmp" "$SESSION_FILE"; then
    say "session entry installed: choose Minflair in your display manager"
  else
    warn "could not write $SESSION_FILE, start from a TTY with: $HOME_DIR/bin/minflair-session"
  fi
  rm -f "$tmp"
}

install_greeter() {
  step "Login screen"
  if [ "$DISTRO" != "debian" ] || [ ! -x "$SRC/tools/install-greeter.sh" ]; then
    warn "the greetd login screen is only supported on Debian/FlickOS"
    return 0
  fi
  sudo "$SRC/tools/install-greeter.sh" || warn "the login screen installer reported a problem"
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
  detect_distro

  if [ "$CHECK" -eq 1 ]; then
    check_status
    exit $?
  fi

  say "${B}Minflair${N} installer ($DISTRO)"
  if [ "$YES" -eq 1 ]; then say "${D}--yes: every question is answered yes and the defaults are used${N}"; fi

  pick_choices

  if decide "$DO_PACKAGES" "Install packages?" y; then install_packages; fi
  check_versions
  if decide "$DO_SHELL" "Install the Quickshell config to $HOME_DIR/quickshell?" y; then install_shell; fi
  if decide "$DO_HYPR" "Install the Hyprland config to $HOME_DIR/hypr?" y; then install_hypr; fi
  if decide "$DO_SESSION" "Install the Minflair login session (needs sudo)?" y; then install_session; fi
  if decide "$DO_SERVICES" "Enable NetworkManager and Bluetooth (needs sudo)?" y; then enable_services; fi
  if [ "$DO_GREETER" = "yes" ] || { [ "$DO_GREETER" = "ask" ] && [ "$YES" -eq 0 ] && [ -d /usr/libexec/flickos ] && confirm "Install the Minflair greetd login screen (needs sudo)?" n; }; then install_greeter; fi

  step "Done"
  say "Log out and choose ${B}Minflair${N} in your display manager, or run ${B}$HOME_DIR/bin/minflair-session${N} from a TTY."
  say "Backups, if any, are in $HOME_DIR/backup. Check the setup any time with ./install.sh --check"
}

main
