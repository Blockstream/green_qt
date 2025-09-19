#!/bin/bash
set -eox pipefail

LIBSERIALPORT_REPO=https://github.com/sigrokproject/libserialport
LIBSERIALPORT_BRANCH=master
LIBSERIALPORT_COMMIT=21b3dfe5f68c205be4086469335fd2fc2ce11ed2

mkdir -p build && cd build

git clone --quiet --depth 1 --branch $LIBSERIALPORT_BRANCH --single-branch $LIBSERIALPORT_REPO libserialport-src
(cd libserialport-src && git rev-parse HEAD && git checkout $LIBSERIALPORT_COMMIT)

mkdir libserialport-bld && cd libserialport-bld

../libserialport-src/autogen.sh

if [ "$HOST" = "linux" ]; then
    ../libserialport-src/configure --prefix=$PREFIX $1
elif [ "$HOST" = "windows" ]; then
    ../libserialport-src/configure --host=x86_64-w64-mingw32 --prefix=$PREFIX $1
elif [ "$HOST" = "macos" ]; then
    ../libserialport-src/configure --prefix=$PREFIX $1
else
    exit 1
fi

make install
