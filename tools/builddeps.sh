#!/bin/bash
set -eo pipefail

export GDKVERSION=$(cd gdk && git rev-parse HEAD)
export QTMAJOR=5.13
export QTVERSION=${QTMAJOR}.1

BUILDDIR=build-linux-gcc

mkdir -p $BUILDDIR

export BUILDROOT=$PWD/$BUILDDIR

./tools/buildqt.sh
echo "Qt: OK"
./tools/buildgdk.sh

echo "GDK: OK"

cd $BUILDROOT

QT_PATH=$BUILDROOT/qt-release-$QTVERSION

export PATH=$QT_PATH/bin:$PATH

$QT_PATH/bin/qmake ../green.pro CONFIG+=release CONFIG+=x86_64 CONFIG+=qml_release CONFIG+=static || true
NUM_JOBS=$(cat /proc/cpuinfo | grep ^processor | wc -l) || true
make -j${NUM_JOBS} || true

strip $BUILDROOT/Green || true
