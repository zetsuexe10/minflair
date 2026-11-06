#!/usr/bin/env bash
set -eu
cd "$(dirname "$0")/.."
S=docs/screenshots
OUT=$S/hero.png
W=1800
H=900
MONO=DejaVu-Sans-Mono-Bold
REG=DejaVu-Sans-Mono
UI=Inter-Medium
UIB=Inter-Bold
T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT

card() {
  local src=$1 w=$2 dst=$3 h
  convert "$src" -resize "${w}x" "$T/raw.png"
  h=$(identify -format %h "$T/raw.png")
  convert -size ${w}x${h} xc:black -fill white -draw "roundrectangle 0,0 $((w-1)),$((h-1)) 26,26" "$T/mask.png"
  convert "$T/raw.png" "$T/mask.png" -alpha off -compose CopyOpacity -composite "$T/round.png"
  convert -size ${w}x${h} xc:none -fill none -stroke '#c4b5fd66' -strokewidth 3 -draw "roundrectangle 1,1 $((w-2)),$((h-2)) 26,26" "$T/edge.png"
  convert "$T/round.png" "$T/edge.png" -composite "$T/framed.png"
  convert "$T/framed.png" \( +clone -background black -shadow 80x34+0+30 \) +swap -background none -layers merge +repage "$dst"
}

chip() {
  local x=$1 y=$2 label=$3 fill=$4 stroke=$5 text=$6 size=${7:-21} tw h=54
  tw=$(convert -font $UIB -pointsize $size -kerning 3 label:"$label" -format %w info:)
  CHIPW=$((tw+44))
  convert "$T/stage.png" \
    -fill "$fill" -stroke "$stroke" -strokewidth 2 -draw "roundrectangle $x,$y $((x+CHIPW)),$((y+h)) 27,27" \
    -stroke none -fill "$text" -font $UIB -pointsize $size -kerning 3 -gravity NorthWest -annotate +$((x+22))+$((y+(h-size)/2-2)) "$label" \
    "$T/stage2.png"
  mv "$T/stage2.png" "$T/stage.png"
}

convert -size ${W}x${H} gradient:'#08050f-#140b28' \
  -fill '#4c1d95' -draw 'circle 1480,140 1480,520' \
  -fill '#831843' -draw 'circle 260,880 260,1100' \
  -blur 0x150 "$T/bg.png"

card $S/convex-aurora.png 700 "$T/a.png"
card $S/style-side.jpg 760 "$T/b.png"
card $S/dynamic-pastel.png 640 "$T/c.png"

convert "$T/bg.png" \
  "$T/a.png" -geometry +1010+40 -composite \
  "$T/b.png" -geometry +900+250 -composite \
  "$T/c.png" -geometry +1100+520 -composite \
  -stroke none \
  -font $MONO -fill '#f5f3ff' -pointsize 132 -kerning 12 -annotate +92+360 'MINFLAIR' \
  -fill '#a78bfa' -draw 'roundrectangle 100,400 220,406 3,3' \
  -font $UI -fill '#d9d3f2' -pointsize 30 -kerning 0 -annotate +100+470 'A Caelestia-flavoured desktop for Hyprland.' \
  -font $UI -fill '#9a8fc7' -pointsize 22 -annotate +100+515 'Four switchable bars, one settings window, everything in one folder.' \
  "$T/stage.png"

X=100
for p in "ARCH LINUX" "DEBIAN 13"; do
  chip $X 150 "$p" '#ffffff14' '#c4b5fd66' '#c4b5fd' 18
  X=$((X+CHIPW+16))
done
X=100
for i in "01  CONVEX" "02  ISLAND" "03  SIDE"; do
  chip $X 560 "$i" '#ffffff10' '#c4b5fd55' '#ede9fe'
  X=$((X+CHIPW+16))
done
chip $X 560 "04  DYNAMIC" '#a78bfa33' '#a78bfa' '#ffffff'

convert "$T/stage.png" \
  -font $REG -fill '#8b7fb8' -pointsize 18 -kerning 4 -annotate +100+740 'QUICKSHELL 0.3  ·  HYPRLAND 0.55+  ·  ~/.MINFLAIR' \
  -font $REG -fill '#6d628f' -pointsize 16 -kerning 3 -annotate +100+780 'SUPER+ALT+1..4 SWITCHES BARS  ·  SUPER+Z QUICK PANEL' \
  "$OUT"
