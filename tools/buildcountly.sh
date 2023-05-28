#!/bin/bash
set -eo pipefail

mkdir -p build

cd build

if [ ! -d countly-sdk-cpp ]; then
    git clone --recurse-submodules --quiet --depth 1 --branch bump --single-branch https://github.com/Blockstream/countly-sdk-cpp countly-sdk-cpp
fi

cd countly-sdk-cpp

cmake . -DCMAKE_INSTALL_PREFIX:PATH=$PREFIX -DBUILD_SHARED_LIBS=0 -DCOUNTLY_BUILD_TESTS=0 -DCOUNTLY_USE_SQLITE=0 -DCOUNTLY_USE_CUSTOM_HTTP=1 -DCOUNTLY_USE_CUSTOM_SHA256=1

make all install
