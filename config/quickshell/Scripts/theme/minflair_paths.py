"""Where Minflair keeps its theme output.

Everything lives under ~/.minflair so the user's real ~/.config GTK/Qt settings
and the gsettings database are never touched. Hyprland sessions started with the
bundled envs.lua point XDG_CONFIG_HOME at ~/.minflair/xdg (an overlay that
symlinks everything else back to ~/.config), so only apps launched from that
session see the Minflair GTK/Qt theme.
"""
import os

HOME = os.environ.get("HOME", os.path.expanduser("~"))
ROOT = os.path.join(HOME, ".minflair")
XDG = os.path.join(ROOT, "xdg")
STATE = os.path.join(ROOT, "theme.json")


def cfg(*parts):
    path = os.path.join(XDG, *parts)
    os.makedirs(os.path.dirname(path) if "." in parts[-1] else path, exist_ok=True)
    return path
