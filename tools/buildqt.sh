#!/bin/bash
set -eo pipefail

QT_MAJOR=6.4
QT_VERSION=${QT_MAJOR}.2
QT_HASH=689f53e6652da82fccf7c2ab58066787487339f28d1ec66a8765ad357f4976be
QT_BASENAME=qt-everywhere-src-${QT_VERSION}
QT_FILENAME=${QT_BASENAME}.tar.xz

mkdir -p build

cd build

if [ ! -f ${QT_FILENAME} ]; then
    echo "qt: downloading"
    curl -s -L -o ${QT_FILENAME} https://download.qt.io/archive/qt/${QT_MAJOR}/${QT_VERSION}/single/${QT_FILENAME}
fi

echo "qt: verifying"
echo "${QT_HASH}  ${QT_FILENAME}" | ${SHA256SUM:-sha256sum} --check

echo "qt: extracting"
rm -rf ${QT_BASENAME}
tar xf ${QT_FILENAME}
cd ${QT_BASENAME}

echo "qt: patching"
patch -p1 < ../../tools/patches/fix-wmf.diff
rm -rf qtwebengine

echo "qt: configuring"
./configure \
  -release \
  -static -static-runtime \
  -prefix $PREFIX \
  -skip qt3d,qtactiveqt,qtcharts,qtcoap,qtdatavis3d,qtdoc,qthttpserver,qtlanguageserver,qtlottie,qtmqtt,qtnetworkauth,qtopcua,qtpositioning,qtquick3d,qtquick3dphysics,qtquicktimeline,qtremoteobjects,qtscxml,qtsensors,qtserialbus,qtspeech,qtvirtualkeyboard,qtwayland,qtwebchannel,qtwebengine,qtwebsockets,qtwebview \
  -no-feature-sql -no-feature-sql-sqlite \
  -nomake tests -nomake examples

echo "qt: building"
cmake --build . --parallel --target install

echo "qt: done"
