#!/bin/bash
set -exo pipefail

PREFIX=$1/countly

git clone --recurse-submodules --quiet --depth 1 --single-branch --branch master https://github.com/Blockstream/countly-sdk-cpp
cd countly-sdk-cpp
mkdir build
cd build
cmake .. -DCMAKE_TOOLCHAIN_FILE=$2 -DCMAKE_INSTALL_PREFIX:PATH=${PREFIX} -DBUILD_SHARED_LIBS=0 -DCOUNTLY_BUILD_TESTS=0 -DCOUNTLY_USE_SQLITE=0 -DCOUNTLY_USE_CUSTOM_HTTP=1 -DCOUNTLY_USE_CUSTOM_SHA256=1
make all install

find ${PREFIX}
