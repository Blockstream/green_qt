#!/bin/bash
set -eo pipefail

mkdir -p build

cd build

if [ ! -d zxing ]; then
    git clone --quiet --depth 1 --branch master --single-branch https://github.com/zxing-cpp/zxing-cpp.git zxing
fi

cd zxing
git rev-parse HEAD

rm -rf build
mkdir build
cd build

cmake .. -DZXING_USE_BUNDLED_ZINT=OFF -DZXING_C_API=OFF -DZXING_EXAMPLES=OFF -DZXING_DEPENDENCIES=LOCAL -DBUILD_SHARED_LIBS=OFF -DCMAKE_INSTALL_PREFIX=$CMAKE_INSTALL_PREFIX -DCMAKE_BUILD_TYPE=Release

make -j install
