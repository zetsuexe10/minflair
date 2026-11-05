#!/usr/bin/env bash
# Why is something not showing? Run inside your Hyprland session.
QS="${MINFLAIR_HOME:-$HOME/.minflair}/bin/qs"; [ -x "$QS" ] || QS=qs
echo "== processes"; pgrep -a quickshell || echo "quickshell is NOT running  ->  start it with: $QS"
echo; echo "== widget sockets (Super+A launcher = quickshell_launcher, etc.)"
ls /tmp/quickshell_* 2>/dev/null || echo "none: the shell did not finish loading, see errors below"
echo; echo "== IPC"; "$QS" ipc show 2>&1 | head -20
echo; echo "== last errors/warnings from the shell"
"$QS" log 2>&1 | grep -E "ERROR|WARN" | tail -25
echo; echo "== session"; echo "XDG_CONFIG_HOME=$XDG_CONFIG_HOME"; echo "QT_QPA_PLATFORM=$QT_QPA_PLATFORM"; hyprctl version 2>/dev/null | head -1; echo "session log: $(tail -n 5 "${XDG_STATE_HOME:-$HOME/.local/state}/minflair/session.log" 2>/dev/null)"
echo; echo "== latest quickshell crash report (send this if the shell or a widget crashes)"
c=$(ls -dt ~/.cache/quickshell/crashes/*/ 2>/dev/null | head -1)
if [ -n "$c" ]; then echo "$c"; head -c 3000 "$c/report.txt" 2>/dev/null; tail -n 40 "$c/log.qslog" 2>/dev/null | strings | tail -25; else echo "no crash reports"; fi
