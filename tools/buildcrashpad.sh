#!/bin/bash
set -eo pipefail

mkdir -p build

cd build

CRASHPAD_REPO=https://github.com/Blockstream/crashpad.git
CRASHPAD_BRANCH=green_qt
CRASHPAD_COMMIT=1a4c92aca24ca52ffb4e3b798d4a3681f37116d4

if [ ! -d crashpad ]; then
    git clone --recurse-submodules --quiet --depth 1 --branch $CRASHPAD_BRANCH --single-branch $CRASHPAD_REPO crashpad
fi

cd crashpad
git rev-parse HEAD
git checkout $CRASHPAD_COMMIT

if [[ "$HOST" == "windows" ]]; then
cp /usr/x86_64-w64-mingw32/include/ntsecapi.h /usr/x86_64-w64-mingw32/include/NTSecAPI.h
cp /usr/x86_64-w64-mingw32/include/windows.h /usr/x86_64-w64-mingw32/include/Windows.h
fi

cmake . -B build -DCMAKE_INSTALL_PREFIX:PATH=$PREFIX -DCRASHPAD_ZLIB_SYSTEM=OFF

make -C build all install

