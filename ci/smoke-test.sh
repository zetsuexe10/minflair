#!/bin/bash
# Load the config with the offscreen Qt platform and fail on QML load errors
# (missing modules, syntax errors, unknown types) or a crash. Wayland-only failures are ignored.
cfg=$(realpath "$1")
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
mkdir -p "$work/run" "$work/home" "$work/cfg"
chmod 700 "$work/run"
log="$work/log"
QT_QPA_PLATFORM=offscreen XDG_RUNTIME_DIR="$work/run" HOME="$work/home" XDG_CONFIG_HOME="$work/cfg" \
  timeout 25 quickshell -p "$cfg" >"$log" 2>&1
status=$?
cat "$log"
if grep -qiE "is not installed|is not a type|syntax error|unexpected token|Failed to load|File not found|Cannot assign|Unable to assign to non-existent" "$log"; then
  echo "SMOKE TEST: QML load errors found" >&2; exit 1
fi
# 124 = still running when the timeout hit (expected); 134/139 = abort/segfault
if [ "$status" -eq 134 ] || [ "$status" -eq 139 ]; then
  echo "SMOKE TEST: quickshell crashed (exit $status)" >&2; exit 1
fi
echo "SMOKE TEST: no QML load errors (exit $status)"
