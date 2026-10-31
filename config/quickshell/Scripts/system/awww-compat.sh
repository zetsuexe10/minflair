#!/bin/sh
# Wallpaper setter. Debian has no awww package: use awww when it is
# installed, otherwise fall back to swaybg (transitions are ignored).
# Usage: awww-compat.sh img <path> [--resize crop|fit|no|stretch] [other awww flags ignored]
if command -v awww >/dev/null 2>&1; then
  pgrep -x awww-daemon >/dev/null || { setsid awww-daemon >/dev/null 2>&1 & sleep 0.5; }
  exec awww "$@"
fi
[ "$1" = "img" ] || exit 1
img="$2"; shift 2
mode=fill
while [ $# -gt 0 ]; do
  case "$1" in
    --resize) case "$2" in fit) mode=fit;; no) mode=center;; stretch) mode=stretch;; *) mode=fill;; esac; shift 2;;
    *) shift;;
  esac
done
command -v swaybg >/dev/null 2>&1 || { echo "install swaybg (or awww)" >&2; exit 1; }
old=$(pgrep -x swaybg)
setsid swaybg -i "$img" -m "$mode" >/dev/null 2>&1 &
sleep 0.3
[ -n "$old" ] && kill $old 2>/dev/null
exit 0
