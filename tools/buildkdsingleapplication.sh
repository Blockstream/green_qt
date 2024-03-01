#!/bin/bash
set -exo pipefail


FILENAME=kdsingleapplication-1.1.0
ARCHIVE=$FILENAME.tar.gz
DIRNAME=$FILENAME

mkdir -p build
cd build

if [ ! -d $DIRNAME ]; then
    curl -s -L -o $ARCHIVE https://github.com/KDAB/KDSingleApplication/releases/download/v1.1.0/$ARCHIVE
    tar zxf $ARCHIVE
fi

mkdir $DIRNAME/build
cd $DIRNAME/build

$PREFIX/bin/qt-cmake .. -DCMAKE_INSTALL_PREFIX=$CMAKE_INSTALL_PREFIX -DKDSingleApplication_QT6=true -DKDSingleApplication_STATIC=true -DKDSingleApplication_TESTS=false -DKDSingleApplication_EXAMPLES=false -DKDSingleApplication_DOCS=false

make install
