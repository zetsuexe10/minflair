#!/bin/bash
# make-deb.sh <staging-root> <version> <outdir>
set -euo pipefail
root=$(realpath "$1"); ver="$2"; out="$3"; mkdir -p "$out"; out=$(realpath "$out")

# Library dependencies, computed from the real binaries.
tmp=$(mktemp -d); mkdir "$tmp/debian"
printf 'Source: quickshell\n\nPackage: quickshell\nArchitecture: any\n' > "$tmp/debian/control"
(cd "$tmp" && dpkg-shlibdeps -O -e"$root/usr/bin/quickshell" 2>/dev/null) | sed 's/^shlibs:Depends=//' > "$tmp/shlibs"
# QML modules are loaded at runtime, so ldd cannot see them.
qml="qml6-module-qtcore, qml6-module-qtqml, qml6-module-qtqml-workerscript, qml6-module-qtquick, \
qml6-module-qtquick-controls, qml6-module-qtquick-templates, qml6-module-qtquick-layouts, \
qml6-module-qtquick-window, qml6-module-qtquick-shapes, qml6-module-qtquick-effects, \
qt6-wayland, libqt6svg6, qt6-image-formats-plugins"
deps="$(cat "$tmp/shlibs"), $qml"

mkdir -p "$root/DEBIAN"
cat > "$root/DEBIAN/control" <<CTL
Package: quickshell
Version: ${ver}-1~trixie1
Architecture: amd64
Maintainer: Minflair builder <noreply@localhost>
Section: x11
Priority: optional
Depends: $deps
Description: Quickshell (QtQuick desktop shell toolkit) built for Debian 13
 Built from upstream by the Minflair CI, because trixie does not ship it.
CTL
dpkg-deb --root-owner-group --build "$root" "$out/quickshell_${ver}-1~trixie1_amd64.deb"
rm -rf "$root/DEBIAN"
dpkg-deb -I "$out"/quickshell_*.deb
