#!/usr/bin/env bash
# Why is something not showing? Run inside your Hyprland session.
echo "== processes"; pgrep -a quickshell || echo "quickshell is NOT running  ->  start it with: qs"
echo; echo "== widget sockets (Super+A launcher = quickshell_launcher, etc.)"
ls /tmp/quickshell_* 2>/dev/null || echo "none: the shell did not finish loading, see errors below"
echo; echo "== IPC"; qs ipc show 2>&1 | head -20
echo; echo "== last errors/warnings from the shell"
qs log 2>&1 | grep -E "ERROR|WARN" | tail -25
echo; echo "== session"; echo "XDG_CONFIG_HOME=$XDG_CONFIG_HOME"; echo "QT_QPA_PLATFORM=$QT_QPA_PLATFORM"; hyprctl version 2>/dev/null | head -1
