#!/bin/bash
set -exo pipefail

mkdir -p build && cd build

git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git

export PATH=$(pwd)/depot_tools:$PATH

mkdir -p breakpad && cd breakpad

fetch breakpad

mkdir build && cd build

if [ "$HOST" = "linux" ]; then
    ../src/configure \
        CXXFLAGS="-static-libgcc -static-libstdc++" \
        LDFLAGS="-static" \
        --prefix=$PREFIX
elif [ "$HOST" = "windows" ]; then
    ../src/configure \
        --host=x86_64-w64-mingw32 \
        CXXFLAGS="-static-libgcc -static-libstdc++" \
        LDFLAGS="-static" \
        --prefix=$PREFIX
elif [ "$HOST" = "macos" ]; then
    export CC=clang
    export CXX=clang++
    ../src/configure --prefix=$PREFIX
else
    exit 1
fi

make -j8
make install

cp src/third_party/libdisasm/libdisasm.a $PREFIX/lib
cp -r ../src/src/google_breakpad $PREFIX/include/breakpad
