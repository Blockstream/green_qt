#!/bin/bash
set -eo pipefail
export GREENPLATFORM=$1

if [ "${GREENPLATFORM}" = "" ]; then
    export BUILDDIR=build-linux-gcc
    GREENPLATFORM="linux"
elif [ "${GREENPLATFORM}" = "linux" ]; then
    export BUILDDIR=build-linux-gcc
elif [ "${GREENPLATFORM}" = "windows" ]; then
    export BUILDDIR=build-mingw-w64
elif [ "${GREENPLATFORM}" = "osx" ]; then
    export BUILDDIR=build-osx-clang
else
    exit 1
fi

DEPS=$(shasum -a 256 ./tools/bionic_deps.sh | cut -d" " -f1)
DEPS="$DEPS $(shasum -a 256 Dockerfile | cut -d" " -f1)"
export GDKBLDID=$(echo $(cd gdk && git rev-parse HEAD) $(shasum -a 256 ./tools/buildgdk.sh | cut -d" " -f1) ${DEPS} | shasum -a 256 | cut -d" " -f1)
export QTMAJOR=5.13
export QTVERSION=${QTMAJOR}.1
export QTBLDID=$(echo ${QTVERSION} ${DEPS} $(shasum -a 256 ./tools/buildqt.sh | cut -d" " -f1) | shasum -a 256 | cut -d" " -f1)
export BUILDROOT=${PWD}/${BUILDDIR}

export QT_PATH=${BUILDROOT}/qt-release-${QTBLDID}

if [ "$(uname)" == "Darwin" ]; then
    export NUM_JOBS=$(sysctl -n hw.ncpu)
else
    export NUM_JOBS=$(cat /proc/cpuinfo | grep ^processor | wc -l)
fi

export PATH=${QT_PATH}/bin:${PATH}
export QTBUILD=${BUILDROOT}/qt-release-${QTBLDID}
export GDKBUILD=${BUILDROOT}/gdk-${GDKBLDID}
