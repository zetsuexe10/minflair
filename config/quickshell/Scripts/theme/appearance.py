#!/usr/bin/env python3
"""App appearance for the Minflair session only: GTK/Qt font, icon theme, cursor theme and size.

Everything is written to ~/.minflair (theme.json + the xdg overlay used by the Minflair Hyprland
session). ~/.config GTK/Qt files and gsettings are never touched, and the shell's own font is
independent of the app font set here.

  appearance.py list            JSON: fonts, icon themes, cursor themes
  appearance.py get             JSON: current values
  appearance.py set '<json>'    keys: gtk_theme, gtk_font, gtk_font_size, icon_theme, cursor, cursor_size
"""
import sys

sys.dont_write_bytecode = True

import configparser
import json
import os
import subprocess

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from minflair_paths import HOME, ROOT, STATE, XDG  # noqa: E402

ICON_DIRS = [
    os.path.join(HOME, ".local/share/icons"),
    os.path.join(HOME, ".icons"),
    "/usr/local/share/icons",
    "/usr/share/icons",
]
THEME_DIRS = [
    os.path.join(HOME, ".themes"),
    os.path.join(HOME, ".local/share/themes"),
    "/usr/local/share/themes",
    "/usr/share/themes",
]
DEFAULTS = {
    "gtk_theme": "",
    "gtk_font": "",
    "gtk_font_size": 11,
    "icon_theme": "",
    "cursor": "",
    "cursor_size": 24,
}


def load():
    try:
        with open(STATE) as f:
            return json.load(f)
    except Exception:
        return {}


def save(st):
    os.makedirs(ROOT, exist_ok=True)
    tmp = STATE + ".tmp"
    with open(tmp, "w") as f:
        json.dump(st, f, indent=2)
    os.replace(tmp, STATE)


def themes():
    icons, cursors = set(), set()
    for d in ICON_DIRS:
        if not os.path.isdir(d):
            continue
        for name in os.listdir(d):
            base = os.path.join(d, name)
            idx = os.path.join(base, "index.theme")
            if not os.path.isfile(idx):
                continue
            if os.path.isdir(os.path.join(base, "cursors")):
                cursors.add(name)
            try:
                text = open(idx, errors="ignore").read()
            except OSError:
                text = ""
            if "Directories=" in text and not name.lower().startswith(("hicolor", "default")) \
                    and not os.path.isdir(os.path.join(base, "cursors")):
                icons.add(name)
    return sorted(icons, key=str.lower), sorted(cursors, key=str.lower)


def gtk_themes():
    found = set()
    for d in THEME_DIRS:
        if not os.path.isdir(d):
            continue
        for name in os.listdir(d):
            base = os.path.join(d, name)
            if os.path.isdir(os.path.join(base, "gtk-3.0")) or os.path.isdir(os.path.join(base, "gtk-4.0")):
                found.add(name)
    return sorted(found, key=str.lower)


def fonts():
    try:
        out = subprocess.run(["fc-list", ":", "family"], capture_output=True, text=True, timeout=15).stdout
    except Exception:
        return []
    fam = {line.split(",")[0].strip() for line in out.splitlines() if line.strip()}
    return sorted(fam, key=str.lower)


def current(st):
    cur = dict(DEFAULTS)
    for k in DEFAULTS:
        if st.get(k) not in (None, ""):
            cur[k] = st[k]
    if not cur["gtk_font"] and st.get("font"):
        # "Family 11" written by the shell font script
        parts = str(st["font"]).rsplit(" ", 1)
        cur["gtk_font"] = parts[0]
        if len(parts) == 2 and parts[1].isdigit():
            cur["gtk_font_size"] = int(parts[1])
    return cur


def set_ini(path, keys):
    lines, seen = [], set()
    if os.path.exists(path):
        for line in open(path).read().splitlines():
            k = line.split("=", 1)[0].strip()
            if k in keys:
                line = f"{k}={keys[k]}"
                seen.add(k)
            lines.append(line)
    if not lines:
        lines = ["[Settings]"]
    for k, v in keys.items():
        if k not in seen:
            lines.append(f"{k}={v}")
    os.makedirs(os.path.dirname(path), exist_ok=True)
    if os.path.islink(path):
        os.remove(path)
    with open(path, "w") as f:
        f.write("\n".join(lines) + "\n")


def hypr(*args):
    try:
        subprocess.run(["hyprctl", *args], capture_output=True, timeout=5)
    except (FileNotFoundError, subprocess.TimeoutExpired):
        pass


def session_env():
    """Make the Minflair overlay the config home of apps started from now on (no re-login)."""
    script = os.path.join(os.path.dirname(os.path.abspath(__file__)), "minflair-env.sh")
    if os.path.exists(script):
        try:
            subprocess.run([script], capture_output=True, timeout=20)
        except (OSError, subprocess.TimeoutExpired):
            pass
    if os.path.isdir(os.path.join(XDG, "gtk-3.0")):
        hypr("setenv", "XDG_CONFIG_HOME", XDG)
        hypr("setenv", "QT_QPA_PLATFORMTHEME", "qt6ct")


def apply(cur, is_dark=True):
    session_env()
    keys = {}
    chosen = cur["gtk_theme"] or ("adw-gtk3-dark" if is_dark else "adw-gtk3")
    keys["gtk-theme-name"] = chosen
    hypr("setenv", "GTK_THEME", chosen)
    if cur["gtk_font"]:
        keys["gtk-font-name"] = f'{cur["gtk_font"]} {cur["gtk_font_size"]}'
    if cur["icon_theme"]:
        keys["gtk-icon-theme-name"] = cur["icon_theme"]
    if cur["cursor"]:
        keys["gtk-cursor-theme-name"] = cur["cursor"]
    keys["gtk-cursor-theme-size"] = cur["cursor_size"]
    for v in ("gtk-3.0", "gtk-4.0"):
        set_ini(os.path.join(XDG, v, "settings.ini"), keys)

    for qtct in ("qt5ct", "qt6ct"):
        path = os.path.join(XDG, qtct, f"{qtct}.conf")
        os.makedirs(os.path.dirname(path), exist_ok=True)
        config = configparser.ConfigParser()
        config.optionxform = str
        if os.path.exists(path):
            config.read(path)
        if cur["gtk_font"]:
            config.setdefault("Fonts", {})
            f = f'{cur["gtk_font"]},{cur["gtk_font_size"]},-1,5,50,0,0,0,0,0'
            config["Fonts"]["general"] = f'"{f}"'
            config["Fonts"]["fixed"] = f'"{f}"'
        if cur["icon_theme"]:
            config.setdefault("Appearance", {})
            config["Appearance"]["icon_theme"] = cur["icon_theme"]
        with open(path, "w") as f:
            config.write(f)

    # cursor: new apps pick it from the session environment, the compositor cursor changes now
    if cur["cursor"]:
        env = {
            "XCURSOR_THEME": cur["cursor"], "HYPRCURSOR_THEME": cur["cursor"],
            "XCURSOR_SIZE": str(cur["cursor_size"]), "HYPRCURSOR_SIZE": str(cur["cursor_size"]),
        }
        for k, v in env.items():
            hypr("setenv", k, v)
        hypr("setcursor", cur["cursor"], str(cur["cursor_size"]))


def main():
    cmd = sys.argv[1] if len(sys.argv) > 1 else "get"
    st = load()
    if cmd == "list":
        icons, cursors = themes()
        print(json.dumps({"fonts": fonts(), "icons": icons, "cursors": cursors, "gtkThemes": gtk_themes()}))
    elif cmd == "get":
        print(json.dumps(current(st)))
    elif cmd == "set":
        try:
            patch = json.loads(sys.argv[2])
        except Exception:
            print("invalid json", file=sys.stderr)
            sys.exit(2)
        cur = current(st)
        for k in DEFAULTS:
            if k in patch:
                cur[k] = patch[k]
        cur["gtk_font_size"] = max(6, min(32, int(cur["gtk_font_size"])))
        cur["cursor_size"] = max(12, min(96, int(cur["cursor_size"])))
        st.update(cur)
        if cur["cursor"]:
            st["cursor"] = cur["cursor"]
        save(st)
        apply(cur, st.get("is_dark", True))
        print(json.dumps(cur))
    else:
        print(__doc__)
        sys.exit(1)


if __name__ == "__main__":
    main()
