#!/usr/bin/env bash
set -eu
cd "$(dirname "$0")/.."
S=docs/screenshots
OUT=$S/hero.png
W=1800
H=900
MONO=DejaVu-Sans-Mono-Bold
REG=DejaVu-Sans-Mono
T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT

card() {
  local src=$1 w=$2 dst=$3 h
  convert "$src" -resize "${w}x" "$T/raw.png"
  h=$(identify -format %h "$T/raw.png")
  convert -size ${w}x${h} xc:black -fill white -draw "roundrectangle 0,0 $((w-1)),$((h-1)) 24,24" "$T/mask.png"
  convert "$T/raw.png" "$T/mask.png" -alpha off -compose CopyOpacity -composite "$T/round.png"
  convert -size ${w}x${h} xc:none -fill none -stroke '#a78bfa88' -strokewidth 3 -draw "roundrectangle 1,1 $((w-2)),$((h-2)) 24,24" "$T/edge.png"
  convert "$T/round.png" "$T/edge.png" -composite "$T/framed.png"
  convert "$T/framed.png" \( +clone -background black -shadow 75x30+0+26 \) +swap -background none -layers merge +repage "$dst"
}

convert -size ${W}x${H} gradient:'#090512-#150c2b' \
  -fill '#4c1d95' -draw 'circle 1500,160 1500,560' \
  -fill '#831843' -draw 'circle 380,860 380,1120' \
  -blur 0x140 \
  \( -size ${W}x${H} xc:none -fill '#ffffff0a' -draw 'rectangle 0,0 1800,1' \) -composite \
  "$T/bg.png"

card $S/style-side.jpg 780 "$T/side.png"
card $S/style-dynamic.jpg 640 "$T/dyn.png"

convert "$T/bg.png" \
  "$T/side.png" -geometry +930+90 -composite \
  "$T/dyn.png" -geometry +1070+440 -composite \
  -font $REG -fill '#c4b5fd' -pointsize 22 -kerning 8 -annotate +100+270 'A MINIMAL DESKTOP FOR ARCH AND DEBIAN' \
  -font $MONO -fill '#f5f3ff' -pointsize 118 -kerning 10 -annotate +92+410 'MINFLAIR' \
  -fill '#a78bfa' -draw 'roundrectangle 100,450 220,456 3,3' \
  -font $REG -fill '#c4b5fd' -pointsize 26 -kerning 8 -annotate +100+540 'QUICKSHELL  ·  HYPRLAND' \
  -font $REG -fill '#9a8fc7' -pointsize 20 -kerning 6 -annotate +100+790 'CONVEX  ·  ISLAND  ·  SIDE  ·  DYNAMIC' \
  -font $REG -fill '#6d628f' -pointsize 17 -kerning 4 -annotate +100+835 'WITH A PINCH OF CAELESTIA' \
  "$OUT"
