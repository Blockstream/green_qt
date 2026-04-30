#!/bin/bash
set -eo pipefail

FILENAME=hidapi-0.15.0
ARCHIVE=$FILENAME.tar.gz
DIRNAME=hidapi-$FILENAME
HASH=5d84dec684c27b97b921d2f3b73218cb773cf4ea915caee317ac8fc73cef8136

mkdir -p build && cd build

if [ ! -d $DIRNAME ]; then
    curl -s -L -o $ARCHIVE https://github.com/libusb/hidapi/archive/refs/tags/$ARCHIVE
    echo "${HASH}  ${ARCHIVE}" | ${SHA256SUM:-sha256sum} --check
    tar zxf $ARCHIVE
fi

cmake -S $DIRNAME -B hidapi-bld \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_OSX_DEPLOYMENT_TARGET=12.0 \
    -DBUILD_SHARED_LIBS=FALSE \
    -DHIDAPI_BUILD_HIDTEST=OFF

cmake --build hidapi-bld
cmake --install hidapi-bld --strip --prefix $PREFIX
