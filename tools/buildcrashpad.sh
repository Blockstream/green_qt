#!/bin/bash
set -exo pipefail

CRASHPAD_REPO=https://github.com/Blockstream/crashpad.git
CRASHPAD_BRANCH=green_qt
CRASHPAD_COMMIT=1c628b0ad424f16d46e8a470e0a6efc9c3f87166

mkdir -p build && cd build

git clone --recurse-submodules --quiet --branch $CRASHPAD_BRANCH --single-branch $CRASHPAD_REPO crashpad-src

(cd crashpad-src && git rev-parse HEAD && git checkout $CRASHPAD_COMMIT)

if [[ "$HOST" == "windows" ]]; then
cp /usr/x86_64-w64-mingw32/include/ntsecapi.h /usr/x86_64-w64-mingw32/include/NTSecAPI.h
cp /usr/x86_64-w64-mingw32/include/windows.h /usr/x86_64-w64-mingw32/include/Windows.h
fi

cmake -S crashpad-src -B crashpad-bld \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_OSX_DEPLOYMENT_TARGET=12.0 \
    -DCRASHPAD_ZLIB_SYSTEM=OFF

cmake --build crashpad-bld
cmake --install crashpad-bld --strip --prefix $PREFIX
