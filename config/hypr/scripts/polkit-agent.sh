#!/bin/sh
# Start whichever polkit authentication agent is installed.
for c in /usr/libexec/hyprpolkitagent /usr/lib/hyprpolkitagent/hyprpolkitagent \
         /usr/lib/policykit-1-gnome/polkit-gnome-authentication-agent-1 \
         /usr/libexec/polkit-gnome-authentication-agent-1 \
         /usr/lib/x86_64-linux-gnu/libexec/polkit-kde-authentication-agent-1 \
         /usr/libexec/polkit-mate-authentication-agent-1; do
  [ -x "$c" ] && exec "$c"
done
command -v hyprpolkitagent >/dev/null 2>&1 && exec hyprpolkitagent
command -v lxpolkit >/dev/null 2>&1 && exec lxpolkit
echo "no polkit agent found" >&2; exit 1
