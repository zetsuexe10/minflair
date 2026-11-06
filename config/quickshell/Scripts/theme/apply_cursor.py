#!/usr/bin/env python3
import sys

sys.dont_write_bytecode = True

import json
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

    appearance = Path(__file__).resolve().parent / "appearance.py"
    subprocess.run(
        [sys.executable, str(appearance), "set", json.dumps({"cursor": theme_name, "cursor_size": int(size)})],
        capture_output=True,
        timeout=30,
    )

    # 3. Update ~/.minflair/hypr/envs.lua for persistence across reboots
    envs_lua = home / ".minflair" / "hypr" / "envs.lua"
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



if __name__ == "__main__":
    main()
