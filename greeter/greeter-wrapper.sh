#!/bin/sh
# Minflair login screen for greetd (installed as /usr/libexec/flickos/greeter).
# Runs the Quickshell greeter inside cage; falls back to gtkgreet if it fails.

# cage ignores the system keyboard layout; pass it on explicitly.
if [ -r /etc/default/keyboard ]; then
    XKB_DEFAULT_MODEL="$(. /etc/default/keyboard; echo "${XKBMODEL:-}")"
    XKB_DEFAULT_LAYOUT="$(. /etc/default/keyboard; echo "${XKBLAYOUT:-}")"
    XKB_DEFAULT_VARIANT="$(. /etc/default/keyboard; echo "${XKBVARIANT:-}")"
    XKB_DEFAULT_OPTIONS="$(. /etc/default/keyboard; echo "${XKBOPTIONS:-}")"
    export XKB_DEFAULT_MODEL XKB_DEFAULT_LAYOUT XKB_DEFAULT_VARIANT XKB_DEFAULT_OPTIONS
fi

# The greeter user (_greetd) has no usable home.
export XDG_CACHE_HOME=/tmp/greeter-cache XDG_STATE_HOME=/tmp/greeter-state XDG_DATA_HOME=/tmp/greeter-data
export QT_QPA_PLATFORM=wayland QT_QUICK_BACKEND="${QT_QUICK_BACKEND:-}"
mkdir -p "$XDG_CACHE_HOME" "$XDG_STATE_HOME" "$XDG_DATA_HOME"

QS="$(command -v quickshell || command -v qs)"
if [ -n "$QS" ] && [ -f /usr/share/minflair/greeter/shell.qml ]; then
    cage -d -s -- "$QS" -p /usr/share/minflair/greeter && exit 0
fi

# Fallback: the stock FlickOS gtkgreet screen.
export GTK_THEME=Arc-Dark
exec cage -d -s -- gtkgreet \
    --command flickos-session \
    --style /usr/share/flickos/greeter/gtkgreet.css
