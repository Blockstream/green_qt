#!/bin/bash
set -exo pipefail

ZXING_REPO=https://github.com/Blockstream/zxing-cpp.git
ZXING_BRANCH=green_qt
ZXING_COMMIT=a920817b6fe0508cc4aca9003003c2812a78e935

mkdir -p build && cd build

git clone --quiet --branch $ZXING_BRANCH --single-branch $ZXING_REPO zxing-cpp-src
(cd zxing-cpp-src && git rev-parse HEAD && git checkout $ZXING_COMMIT)

cmake -S zxing-cpp-src -B zxing-cpp-bld \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_OSX_DEPLOYMENT_TARGET=12.0 \
  -DBUILD_SHARED_LIBS=OFF \
  -DZXING_C_API=OFF \
  -DZXING_EXAMPLES=OFF \
  -DZXING_DEPENDENCIES=LOCAL \
  -DZXING_USE_BUNDLED_ZINT=OFF

cmake --build zxing-cpp-bld
cmake --install zxing-cpp-bld --strip --prefix $PREFIX
