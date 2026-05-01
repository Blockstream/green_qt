#!/bin/bash
set -eox pipefail

REPO=https://github.com/Blockstream/lwk
COMMIT=bdbf0904466c51985f262d8ad2d5436951d80a3e

mkdir -p build && cd build

rm -rf lwk-src
git clone --recurse-submodules --quiet $REPO lwk-src

cd lwk-src
git rev-parse HEAD
git checkout $COMMIT

if [ "$HOST" = "windows" ]; then
    cargo build --target x86_64-pc-windows-gnu --release -p lwk_bindings
    cd target/x86_64-pc-windows-gnu/release
    gendef lwk.dll
    install -d $PREFIX/bin
    install lwk.dll $PREFIX/bin
    install lwk.def $PREFIX/bin
elif [ "$HOST" = "macos" ]; then
    cargo build --release -p lwk_bindings
    install -d $PREFIX/lib
    install target/release/liblwk.dylib $PREFIX/lib
    install_name_tool -id @rpath/liblwk.dylib $PREFIX/lib/liblwk.dylib
else
    cargo build --release -p lwk_bindings
    install -d $PREFIX/lib
    install ./target/release/liblwk.so $PREFIX/lib
fi

# cargo install uniffi-bindgen-cpp --git https://github.com/NordSecurity/uniffi-bindgen-cpp --tag v0.8.1+v0.29.4
# uniffi-bindgen-cpp --library target/release/liblwk.dylib --out-dir ../../src/lwk
