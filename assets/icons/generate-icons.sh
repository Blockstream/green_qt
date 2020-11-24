#!/bin/bash
set -eo pipefail

# this script generates icons from the original .svg icon
# inkscape binary must be in PATH

ICON=green

# generate linux and qt window icon
inkscape -w  512 -h  512 $ICON.svg -o $ICON.png

# generate macos icon
ICONSET=$ICON.iconset
rm -rf $ICONSET && mkdir $ICONSET
inkscape -w   16 -h   16 $ICON.svg -o $ICONSET/icon_16x16.png
inkscape -w   32 -h   32 $ICON.svg -o $ICONSET/icon_16x16@2x.png
inkscape -w   32 -h   32 $ICON.svg -o $ICONSET/icon_32x32.png
inkscape -w   64 -h   64 $ICON.svg -o $ICONSET/icon_32x32@2x.png
inkscape -w  128 -h  128 $ICON.svg -o $ICONSET/icon_128x128.png
inkscape -w  256 -h  256 $ICON.svg -o $ICONSET/icon_128x128@2x.png
inkscape -w  256 -h  256 $ICON.svg -o $ICONSET/icon_256x256.png
inkscape -w  512 -h  512 $ICON.svg -o $ICONSET/icon_256x256@2x.png
inkscape -w  512 -h  512 $ICON.svg -o $ICONSET/icon_512x512.png
inkscape -w 1024 -h 1024 $ICON.svg -o $ICONSET/icon_512x512@2x.png
iconutil -c icns $ICONSET
rm -rf $ICONSET

# generate windows icon
rm -rf ico && mkdir ico
inkscape -w   16 -h   16 $ICON.svg -o ico/icon_16x16.png
inkscape -w   32 -h   32 $ICON.svg -o ico/icon_32x32.png
inkscape -w  128 -h  128 $ICON.svg -o ico/icon_128x128.png
inkscape -w  256 -h  256 $ICON.svg -o ico/icon_256x256.png
convert ico/*.png $ICON.ico
rm -rf ico
