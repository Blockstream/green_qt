#!/bin/bash
set -eox pipefail

COUNTLY_REPO=https://github.com/Blockstream/countly-sdk-cpp
COUNTLY_BRANCH=bump2
COUNTLY_COMMIT=13ff517e12966be52e02677aadd654ff241a5bfc

mkdir -p build && cd build

if [ ! -d countly-src ]; then
    git clone --recurse-submodules --quiet --depth 1 --branch $COUNTLY_BRANCH --single-branch $COUNTLY_REPO countly-src
fi

(cd countly-src && git rev-parse HEAD && git checkout $COUNTLY_COMMIT)

cmake -S countly-src -B countly-bld \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_OSX_DEPLOYMENT_TARGET=12.0 \
    -DBUILD_SHARED_LIBS=OFF \
    -DCOUNTLY_BUILD_TESTS=OFF \
    -DCOUNTLY_USE_SQLITE=OFF \
    -DCOUNTLY_USE_CUSTOM_HTTP=ON \
    -DCOUNTLY_USE_CUSTOM_SHA256=ON

cmake --build countly-bld
cmake --install countly-bld --strip --prefix $PREFIX
