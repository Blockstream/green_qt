#!/bin/bash
set -eo pipefail

mkdir -p build

cd build

curl -s -L -o ffmpeg-7.1.tar.x https://www.ffmpeg.org/releases/ffmpeg-7.1.tar.xz

tar xf ffmpeg-7.1.tar.x

cd ffmpeg-7.1

./configure \
  --prefix=$PREFIX \
  --enable-static \
  --disable-shared \
  --disable-encoders \
  --disable-muxers \
  --enable-gpl \
  --enable-decoder=h264,vp9,aac,mp3,opus \
  --enable-demuxer=mov,matroska,mp4 \
  --disable-debug \
  --disable-programs \
  --disable-doc

make

make install

