#!/bin/bash
set -eo pipefail

VERSION=1.0.29
DIRNAME=libusb-${VERSION}
ARCHIVE=${DIRNAME}.tar.gz
HASH=7c2dd39c0b2589236e48c93247c986ae272e27570942b4163cb00a060fcf1b74

mkdir -p build && cd build

if [ ! -d $DIRNAME ]; then
    curl -s -L -o $ARCHIVE https://github.com/libusb/libusb/archive/refs/tags/v${VERSION}.tar.gz
    echo "${HASH}  ${ARCHIVE}" | ${SHA256SUM:-sha256sum} --check
    tar zxf $ARCHIVE
fi

cd $DIRNAME

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
