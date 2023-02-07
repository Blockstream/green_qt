#!/bin/bash
set -eo pipefail

mkdir -p build

cd build

if [ ! -d libusb ]; then
    git clone --quiet --depth 1 --branch v1.0.26 --single-branch https://github.com/libusb/libusb.git libusb
fi

cd libusb

./bootstrap.sh
if [ "$HOST" = "linux" ]; then
    ./configure --prefix=$PREFIX --disable-shared
elif [ "$HOST" = "windows" ]; then
    ./configure --host=x86_64-w64-mingw32 --prefix=$PREFIX --disable-shared
elif [ "$HOST" = "macos" ]; then
    ./configure --prefix=$PREFIX --disable-shared
else
    exit 1
fi

make -j install
