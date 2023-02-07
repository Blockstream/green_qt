#!/bin/bash
set -eo pipefail


FILENAME=hidapi-0.13.1
ARCHIVE=$FILENAME.tar.gz
DIRNAME=hidapi-$FILENAME

mkdir -p build

cd build

if [ ! -d $DIRNAME ]; then
    curl -s -L -o $ARCHIVE https://github.com/libusb/hidapi/archive/refs/tags/$ARCHIVE
    tar zxf $ARCHIVE
fi

cd $DIRNAME

cmake -DBUILD_SHARED_LIBS=FALSE -DHIDAPI_BUILD_HIDTEST=OFF -DCMAKE_INSTALL_PREFIX=$CMAKE_INSTALL_PREFIX

make -j install
