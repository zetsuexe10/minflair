#!/bin/bash
# Load the config with the offscreen Qt platform and fail on QML load errors
# (missing modules, syntax errors, unknown types). Wayland-only failures are ignored.
cfg=$(realpath "$1")
log=$(mktemp)
QT_QPA_PLATFORM=offscreen XDG_RUNTIME_DIR=$(mktemp -d) HOME=$(mktemp -d) \
  timeout 25 quickshell -p "$cfg" >"$log" 2>&1
cat "$log"
if grep -qiE "is not installed|is not a type|syntax error|unexpected token|Failed to load|File not found|Cannot assign|Unable to assign to non-existent" "$log"; then
  echo "SMOKE TEST: QML load errors found" >&2; exit 1
fi
echo "SMOKE TEST: no QML load errors"
