#!/bin/bash
set -eo pipefail

FILENAME=hidapi-0.14.0
ARCHIVE=$FILENAME.tar.gz
DIRNAME=hidapi-$FILENAME

mkdir -p build && cd build

if [ ! -d $DIRNAME ]; then
    curl -s -L -o $ARCHIVE https://github.com/libusb/hidapi/archive/refs/tags/$ARCHIVE
    tar zxf $ARCHIVE
fi

cmake -S $DIRNAME -B hidapi-bld \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_OSX_DEPLOYMENT_TARGET=12.0 \
    -DBUILD_SHARED_LIBS=FALSE \
    -DHIDAPI_BUILD_HIDTEST=OFF

cmake --build hidapi-bld
cmake --install hidapi-bld --strip --prefix $PREFIX
