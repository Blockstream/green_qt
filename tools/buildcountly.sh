#!/bin/bash
set -eo pipefail

COUNTLY_BRANCH=bump
COUNTLY_COMMIT=a9f703a891f15683308e8c9b947a75597dd3b2fc

mkdir -p build

cd build

if [ ! -d countly-sdk-cpp ]; then
    git clone --recurse-submodules --quiet --depth 1 --branch $COUNTLY_BRANCH --single-branch https://github.com/Blockstream/countly-sdk-cpp countly-sdk-cpp
fi

cd countly-sdk-cpp
git rev-parse HEAD
git checkout $COUNTLY_COMMIT

cmake . -DCMAKE_INSTALL_PREFIX:PATH=$PREFIX -DBUILD_SHARED_LIBS=0 -DCOUNTLY_BUILD_TESTS=0 -DCOUNTLY_USE_SQLITE=0 -DCOUNTLY_USE_CUSTOM_HTTP=1 -DCOUNTLY_USE_CUSTOM_SHA256=1

make all install
