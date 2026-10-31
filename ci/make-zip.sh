#!/bin/bash
# make-zip.sh <outdir>  (expects quickshell .deb in it)
set -euo pipefail
out=$(realpath "$1"); name=minflair-quickshell-trixie
d=$(mktemp -d)/$name; mkdir -p "$d/debs"
cp "$out"/quickshell_*.deb "$d/debs/"
mkdir "$d/config"; cp -a config/quickshell config/hypr "$d/config/"
cp debian/install.sh debian/uninstall.sh debian/README.md "$d/"
chmod +x "$d/install.sh" "$d/uninstall.sh"
(cd "$(dirname "$d")" && zip -qr "$out/$name.zip" "$name")
unzip -l "$out/$name.zip" | tail -3
