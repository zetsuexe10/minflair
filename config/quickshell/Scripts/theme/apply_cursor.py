#!/usr/bin/env python3
import sys

sys.dont_write_bytecode = True

import re
import subprocess
from pathlib import Path


def main():
    if len(sys.argv) < 3:
        print("Usage: apply_cursor.py <ThemeName> <Size>")
        sys.exit(1)

    theme_name = sys.argv[1]
    size = sys.argv[2]
    home = Path.home()

    # 1. Remember the cursor for the Minflair GTK settings (no gsettings, no ~/.icons)
    from minflair_paths import ROOT, STATE
    import json
    st = {}
    try:
        st = json.loads(Path(STATE).read_text())
    except Exception:
        pass
    st["cursor"] = theme_name
    Path(ROOT).mkdir(parents=True, exist_ok=True)
    Path(STATE).write_text(json.dumps(st, indent=2))

    # 3. Update ~/.config/hypr/envs.lua for persistence across reboots
    envs_lua = home / ".config" / "hypr" / "envs.lua"
    if envs_lua.is_file():
        try:
            content = envs_lua.read_text(encoding="utf-8")
            content = re.sub(
                r'hl\.env\("XCURSOR_THEME", ".*?"\)',
                f'hl.env("XCURSOR_THEME", "{theme_name}")',
                content,
            )
            content = re.sub(
                r'hl\.env\("HYPRCURSOR_THEME", ".*?"\)',
                f'hl.env("HYPRCURSOR_THEME", "{theme_name}")',
                content,
            )
            content = re.sub(
                r'hl\.env\("XCURSOR_SIZE", ".*?"\)',
                f'hl.env("XCURSOR_SIZE", "{size}")',
                content,
            )
            content = re.sub(
                r'hl\.env\("HYPRCURSOR_SIZE", ".*?"\)',
                f'hl.env("HYPRCURSOR_SIZE", "{size}")',
                content,
            )
            envs_lua.write_text(content, encoding="utf-8")
        except Exception as e:
            print(f"Warning: Failed to update envs.lua: {e}", file=sys.stderr)

    # 4. Apply via hyprctl (runtime)
    subprocess.run(["hyprctl", "setcursor", theme_name, size], capture_output=True)


if __name__ == "__main__":
    main()
