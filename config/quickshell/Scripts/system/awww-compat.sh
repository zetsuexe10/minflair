#!/bin/sh
# Wallpaper setter using swaybg (no awww). Keeps awww's CLI so callers don't change.
# Usage: awww-compat.sh img <path> [--resize crop|fit|no|stretch] [other flags ignored]
[ "$1" = "img" ] || exit 1
img="$2"; shift 2
mode=fill
while [ $# -gt 0 ]; do
  case "$1" in
    --resize) case "$2" in fit) mode=fit;; no) mode=center;; stretch) mode=stretch;; *) mode=fill;; esac; shift 2;;
    *) shift;;
  esac
done
command -v swaybg >/dev/null 2>&1 || { echo "swaybg not installed" >&2; exit 1; }
old=$(pgrep -x swaybg)
setsid swaybg -i "$img" -m "$mode" >/dev/null 2>&1 &
sleep 0.3
[ -n "$old" ] && kill $old 2>/dev/null
exit 0
