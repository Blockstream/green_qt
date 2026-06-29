#!/bin/bash
set -exo pipefail

ZXING_REPO=https://github.com/Blockstream/zxing-cpp.git
ZXING_COMMIT=4103a03c62e350913e994920157d916b4cc9632a

mkdir -p build && cd build

git clone --quiet --no-checkout $ZXING_REPO zxing-cpp-src
(cd zxing-cpp-src && git rev-parse HEAD && git checkout $ZXING_COMMIT && git submodule update --init --recursive)

cmake -S zxing-cpp-src -B zxing-cpp-bld \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_OSX_DEPLOYMENT_TARGET=12.0 \
  -DBUILD_SHARED_LIBS=OFF \
  -DZXING_C_API=OFF \
  -DZXING_EXAMPLES=OFF \
  -DZXING_DEPENDENCIES=LOCAL \
  -DZXING_USE_BUNDLED_ZINT=ON

cmake --build zxing-cpp-bld
cmake --install zxing-cpp-bld --strip --prefix $PREFIX
