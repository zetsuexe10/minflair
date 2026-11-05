#!/usr/bin/env bash
set -u

HOME_DIR="${MINFLAIR_HOME:-$HOME/.minflair}"
SESSION_FILE="/usr/share/wayland-sessions/minflair.desktop"
YES=0
KEEP_DATA=0

for a in "$@"; do
  case "$a" in
    -y|--yes) YES=1 ;;
    --keep-data) KEEP_DATA=1 ;;
    -h|--help)
      printf 'usage: ./uninstall.sh [--yes] [--keep-data]\n\nRemoves the Minflair session entry and %s (shell, Hyprland config, theme output, backups).\nYour ~/.config is never touched and packages are never removed.\n--keep-data keeps the theme output and backups and removes only the shell, Hyprland config and launchers.\n' "$HOME_DIR"
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
[ -n "$HOME_DIR" ] && [ "$HOME_DIR" != "/" ] && [ "$HOME_DIR" != "$HOME" ] || { printf 'refusing to use %s as the Minflair directory\n' "$HOME_DIR" >&2; exit 1; }

if [ -f "$SESSION_FILE" ] && confirm "Remove $SESSION_FILE (needs sudo)?"; then
  sudo rm -f "$SESSION_FILE" && echo "removed session entry"
fi

if command -v qs >/dev/null 2>&1 && [ -d "$HOME_DIR/quickshell" ]; then
  qs -p "$HOME_DIR/quickshell" kill >/dev/null 2>&1 || true
fi

if [ "$KEEP_DATA" -eq 1 ]; then
  if confirm "Remove the shell, Hyprland config and launchers in $HOME_DIR?"; then
    for d in quickshell hypr bin; do
      [ -e "$HOME_DIR/$d" ] && rm -rf "${HOME_DIR:?}/${d:?}"
    done
    echo "removed"
  fi
elif [ -d "$HOME_DIR" ] && confirm "Remove $HOME_DIR?"; then
  rm -rf "${HOME_DIR:?}"
  echo "removed $HOME_DIR"
fi

rm -f "${XDG_CACHE_HOME:-$HOME/.cache}/quickshell/settings_prefs.json" 2>/dev/null || true
echo "done"
