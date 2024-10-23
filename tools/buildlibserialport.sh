#!/bin/bash
set -eo pipefail

LIBSERIALPORT_BRANCH=master
LIBSERIALPORT_COMMIT=21b3dfe5f68c205be4086469335fd2fc2ce11ed2

mkdir -p build

cd build

if [ ! -d libserialport ]; then
    git clone --quiet --depth 1 --branch $LIBSERIALPORT_BRANCH --single-branch git://sigrok.org/libserialport libserialport
fi

cd libserialport

git rev-parse HEAD
git checkout $LIBSERIALPORT_COMMIT

./autogen.sh

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
