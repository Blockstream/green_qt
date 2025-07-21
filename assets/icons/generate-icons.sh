#!/bin/bash
set -xeo pipefail

# this script generates icons from the original .svg icon
# inkscape binary must be in PATH

FILENAME=$(basename -- "$1")
NAME="${FILENAME%.*}"
ICON="$NAME.png"
S=824
X1=$(((1024-S)/2))
X2=$((X1+S))
R=128

magick -size 1024x1024 xc:none -draw "roundrectangle $X1,$X1,$X2,$X2,$R,$R" mask.png
magick "$1" -resize $((S+2))x$((S+2)) -background black -gravity center -extent 1024x1024 padded.png
magick padded.png -alpha Set mask.png -compose DstIn -composite $ICON
cp $ICON mac_$ICON

# generate linux icon
magick -define profile:skip=icc $1 -resize 512x512 PNG32:linux_$NAME.png

# generate macos icon
ICONSET=$NAME.iconset
rm -rf $ICONSET && mkdir $ICONSET
magick -define profile:skip=icc $ICON -resize 16x16 PNG32:$ICONSET/icon_16x16.png
magick -define profile:skip=icc $ICON -resize 32x32 PNG32:$ICONSET/icon_16x16@2x.png
magick -define profile:skip=icc $ICON -resize 32x32 PNG32:$ICONSET/icon_32x32.png
magick -define profile:skip=icc $ICON -resize 64x64 PNG32:$ICONSET/icon_32x32@2x.png
magick -define profile:skip=icc $ICON -resize 128x128 PNG32:$ICONSET/icon_128x128.png
magick -define profile:skip=icc $ICON -resize 256x256 PNG32:$ICONSET/icon_128x128@2x.png
magick -define profile:skip=icc $ICON -resize 256x256 PNG32:$ICONSET/icon_256x256.png
magick -define profile:skip=icc $ICON -resize 512x512 PNG32:$ICONSET/icon_256x256@2x.png
magick -define profile:skip=icc $ICON -resize 512x512 PNG32:$ICONSET/icon_512x512.png
magick -define profile:skip=icc $ICON -resize 1024x1024 PNG32:$ICONSET/icon_512x512@2x.png
iconutil -c icns $ICONSET
rm -rf $ICONSET

# generate windows icon

magick -size 1024x1024 xc:none -draw "roundrectangle 0,0,1024,1024,$R,$R" mask.png
magick "$1" -alpha Set mask.png -compose DstIn -composite $ICON

rm -rf ico && mkdir ico
magick -define profile:skip=icc $ICON -resize 16x16 PNG32:ico/icon_16x16.png
magick -define profile:skip=icc $ICON -resize 32x32 PNG32:ico/icon_32x32.png
magick -define profile:skip=icc $ICON -resize 64x64 PNG32:ico/icon_64x64.png
magick -define profile:skip=icc $ICON -resize 128x128 PNG32:ico/icon_128x128.png
magick -define profile:skip=icc $ICON -resize 256x256 PNG32:ico/icon_256x256.png
magick ico/*.png $NAME.ico
rm -rf ico

# clean

rm padded.png mask.png
