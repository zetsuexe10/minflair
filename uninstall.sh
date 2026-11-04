#!/usr/bin/env bash
set -u

HOME_DIR="${MINFLAIR_HOME:-$HOME/.minflair}"
CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}"
SESSION_FILE="/usr/share/wayland-sessions/minflair.desktop"
YES=0
KEEP_CONFIG=0

for a in "$@"; do
  case "$a" in
    -y|--yes) YES=1 ;;
    --keep-config) KEEP_CONFIG=1 ;;
    -h|--help)
      printf 'usage: ./uninstall.sh [--yes] [--keep-config]\n\nRemoves the Minflair session entry, ~/.minflair and the installed Quickshell and Hyprland configs.\nPackages are never removed. The newest backup in ~/.minflair/backup is offered back.\n'
      exit 0 ;;
    *) printf 'unknown option: %s\n' "$a" >&2; exit 1 ;;
  esac
done

confirm() {
  [ "$YES" -eq 1 ] && return 0
  [ -t 0 ] || return 1
  local r
  read -r -p "$1 [y/N] " r || r=""
  case "$r" in [Yy]*) return 0 ;; *) return 1 ;; esac
}

[ "$(id -u)" -ne 0 ] || { printf 'do not run this as root\n' >&2; exit 1; }
[ -n "${HOME:-}" ] || { printf 'HOME is not set\n' >&2; exit 1; }

if [ -f "$SESSION_FILE" ] && confirm "Remove $SESSION_FILE (needs sudo)?"; then
  sudo rm -f "$SESSION_FILE" && echo "removed session entry"
fi

latest=""
[ -d "$HOME_DIR/backup" ] && latest="$(ls -1d "$HOME_DIR"/backup/*/ 2>/dev/null | sort | tail -n1)"

if [ "$KEEP_CONFIG" -eq 0 ]; then
  for d in quickshell hypr; do
    if [ -e "$CONFIG/$d" ] && confirm "Remove $CONFIG/$d?"; then
      rm -rf "${CONFIG:?}/${d:?}"
      if [ -n "$latest" ] && [ -e "$latest/$d" ] && confirm "Restore your previous $d from $latest?"; then
        mv "$latest/$d" "$CONFIG/$d"
        echo "restored $d"
      fi
    fi
  done
fi

if [ -d "$HOME_DIR" ] && confirm "Remove $HOME_DIR (theme output, session launcher, backups)?"; then
  rm -rf "${HOME_DIR:?}"
fi

rm -f "${XDG_CACHE_HOME:-$HOME/.cache}/quickshell/settings_prefs.json" 2>/dev/null || true
echo "done"
