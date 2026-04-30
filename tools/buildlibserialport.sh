#!/bin/bash
set -eox pipefail

REPO=https://github.com/sigrokproject/libserialport
COMMIT=21b3dfe5f68c205be4086469335fd2fc2ce11ed2

mkdir -p build && cd build

curl -sL $REPO/archive/$COMMIT.tar.gz | tar xz
mv libserialport-$COMMIT libserialport-src

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
