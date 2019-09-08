#!/bin/bash
set -eo pipefail

export GREENPLATFORM=$1

export GDKBLDID=$(echo $(cd gdk && git rev-parse HEAD) $(sha256sum ./tools/buildgdk.sh | cut -d" " -f1) | sha256sum | cut -d" " -f1)
export QTMAJOR=5.13
export QTVERSION=${QTMAJOR}.1
export QTBLDID=$(echo ${QTVERSION} $(sha256sum ./tools/buildqt.sh | cut -d" " -f1) | sha256sum | cut -d" " -f1)

if [ "${GREENPLATFORM}" = "" ]; then
    BUILDDIR=build-linux-gcc
    GREENPLATFORM="linux"
elif [ "${GREENPLATFORM}" = "linux" ]; then
    BUILDDIR=build-linux-gcc
elif [ "${GREENPLATFORM}" = "windows" ]; then
    BUILDDIR=build-mingw-w64
else
    exit 1
fi

mkdir -p ${BUILDDIR}

export BUILDROOT=${PWD}/${BUILDDIR}

QT_PATH=${BUILDROOT}/qt-release-${QTBLDID}

./tools/buildqt.sh || (cat ${QT_PATH}/build.log && false)
echo "Qt: OK"
./tools/buildgdk.sh || (cat ${BUILDROOT}/gdk-${GDKBLDID}/build.log && false)
echo "GDK: OK"

cd ${BUILDROOT}

export PATH=${QT_PATH}/bin:${PATH}

if [ "${GREENPLATFORM}" = "linux" ]; then
    ${QT_PATH}/bin/qmake ../green.pro CONFIG+=release CONFIG+=x86_64 CONFIG+=qml_release CONFIG+=static QMAKE_CXXFLAGS_RELEASE+=-flto QMAKE_LDFLAGS_RELEASE+=-flto
elif [ "${GREENPLATFORM}" = "windows" ]; then
    ${QT_PATH}/bin/qmake -spec win32-g++ ../green.pro CONFIG+=x86_64 CONFIG+=release CONFIG+=qml_release CONFIG+=static TARGET_BIT=m64
fi


NUM_JOBS=$(cat /proc/cpuinfo | grep ^processor | wc -l)
make -j${NUM_JOBS}

if [ "${GREENPLATFORM}" = "linux" ]; then
    strip ${BUILDROOT}/Green
fi
