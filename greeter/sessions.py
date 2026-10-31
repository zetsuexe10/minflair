#!/usr/bin/env python3
"""Lists login users and installed sessions for the Minflair greeter (prints JSON).

`sessions.py --save USER SESSION` remembers the last choice.
"""
import glob
import json
import os
import pwd
import shlex
import sys

STATE = "/var/tmp/minflair-greeter/last.json"


def load_last():
    try:
        with open(STATE) as f:
            return json.load(f)
    except Exception:
        return {}


def desktop_entries(directory, wrap):
    out = []
    for path in sorted(glob.glob(os.path.join(directory, "*.desktop"))):
        name = exe = ""
        hidden = False
        try:
            with open(path, encoding="utf-8", errors="replace") as f:
                in_entry = False
                for line in f:
                    line = line.strip()
                    if line.startswith("["):
                        in_entry = line == "[Desktop Entry]"
                    elif in_entry and line.startswith("Name=") and not name:
                        name = line[5:]
                    elif in_entry and line.startswith("Exec=") and not exe:
                        exe = line[5:]
                    elif in_entry and line in ("Hidden=true", "NoDisplay=true"):
                        hidden = True
        except OSError:
            continue
        if hidden or not name or not exe:
            continue
        parts = [p for p in shlex.split(exe) if not p.startswith("%")]
        if not parts:
            continue
        argv = (["startx"] + parts) if wrap else parts
        out.append({"name": name + (" (X11)" if wrap else ""), "exec": shlex.join(argv), "argv": argv})
    return out


def main():
    if len(sys.argv) > 1 and sys.argv[1] == "--save":
        try:
            with open(STATE, "w") as f:
                json.dump({"user": sys.argv[2], "session": sys.argv[3]}, f)
            os.chmod(STATE, 0o666)
        except Exception:
            pass
        return

    users = [p.pw_name for p in pwd.getpwall()
             if 1000 <= p.pw_uid < 60000 and not p.pw_shell.endswith(("nologin", "false"))]
    last = load_last()
    if last.get("user") in users:
        users.remove(last["user"])
        users.insert(0, last["user"])

    sessions = []
    if os.path.exists("/usr/bin/flickos-session"):
        sessions.append({"name": "FlickOS", "exec": "flickos-session", "argv": ["flickos-session"]})
    sessions += desktop_entries("/usr/share/wayland-sessions", False)
    sessions += desktop_entries("/usr/share/xsessions", True)
    seen, uniq = set(), []
    for s in sessions:
        if s["exec"] not in seen:
            seen.add(s["exec"])
            uniq.append(s)
    if not uniq:
        uniq = [{"name": "Shell", "exec": "bash -l", "argv": ["bash", "-l"]}]

    default = 0
    names = [s["name"] for s in uniq]
    if last.get("session") in names:
        default = names.index(last["session"])
    else:
        for i, s in enumerate(uniq):
            if "hyprland" in s["exec"].lower() and "uwsm" not in s["exec"].lower():
                default = i
                break
    print(json.dumps({"users": users, "sessions": uniq, "default": default}))


main()
