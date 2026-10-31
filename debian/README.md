# Minflair Quickshell - Debian 13 (trixie) port

Quickshell shell config only (bar styles Convex / Island / Gaming, control center, launcher, notifications, ...).
Hyprland dotfiles are not part of this bundle yet.

```bash
unzip minflair-quickshell-trixie.zip && cd minflair-quickshell-trixie
./install.sh
qs            # inside a Wayland session (Hyprland, sway, ...)
```

What changed vs. the Arch version
- Quickshell is not packaged in trixie: CI builds it and ships it as `debs/quickshell_*.deb`.
- Updates card and system info use apt/dpkg instead of pacman/yay.
- Package Manager window removed (it was a pacman/AUR frontend).
- Wallpapers: `Scripts/system/awww-compat.sh` uses `awww` if present, else `swaybg`.
- Needs a compositor with layer-shell. The `qs ipc` calls used by the keybinds work the same.
- Fonts: the UI uses "Geist"; install it manually if you want the original look (Qt falls back otherwise).
