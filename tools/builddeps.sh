#!/bin/bash
set -eo pipefail

export GREENPLATFORM=$1

if [ "${GREENPLATFORM}" = "linux" ]; then
    BUILDDIR=build-linux-gcc
elif [ "${GREENPLATFORM}" = "windows" ]; then
    BUILDDIR=build-mingw-w64
elif [ "${GREENPLATFORM}" = "osx" ]; then
    BUILDDIR=build-osx-clang
else
    echo "Unsupported target"
    exit 1
fi

if [ "$2" != "" ]; then
    echo "All symbols unstripped mode on"
    GREENSYMBOLS="1"
fi


DEPS=$(shasum -a 256 ./tools/bionic_deps.sh | cut -d" " -f1)
DEPS="$DEPS $(shasum -a 256 Dockerfile | cut -d" " -f1)"
export GDKBLDID=$(echo $(cd gdk && git rev-parse HEAD) $(shasum -a 256 ./tools/buildgdk.sh | cut -d" " -f1) ${DEPS} | shasum -a 256 | cut -d" " -f1)
export QTMAJOR=5.14
export QTVERSION=${QTMAJOR}.0
export QTBLDID=$(echo ${QTVERSION} ${DEPS} $(shasum -a 256 ./tools/buildqt.sh | cut -d" " -f1) | shasum -a 256 | cut -d" " -f1)

mkdir -p ${BUILDDIR}

export BUILDROOT=${PWD}/${BUILDDIR}

export QT_PATH=${BUILDROOT}/qt-release-${QTBLDID}
export GDK_PATH=${BUILDROOT}/gdk-${GDKBLDID}

if [ "$(uname)" == "Darwin" ]; then
    export NUM_JOBS=$(sysctl -n hw.ncpu)
else
    export NUM_JOBS=$(cat /proc/cpuinfo | grep ^processor | wc -l)
fi

./tools/buildqt.sh || (cat ${QT_PATH}/build.log && false)
echo "Qt: OK"
./tools/buildgdk.sh || (cat ${GDK_PATH}/build.log && false)
echo "GDK: OK"

cd ${BUILDROOT}

export PATH=${QT_PATH}/bin:${PATH}
GREEN_QMAKE_CONFIG="CONFIG+=release CONFIG+=qml_release CONFIG+=static"
if [ "${GREENPLATFORM}" != "windows" ]; then
    GREEN_QMAKE_CONFIG+=" QMAKE_CXXFLAGS_RELEASE+=-flto QMAKE_LDFLAGS_RELEASE+=-flto"
fi

if [ "${GREENSYMBOLS}" != "" ]; then
    GREEN_QMAKE_CONFIG+=" QMAKE_CXXFLAGS+=-g"
fi


if [ "${GREENPLATFORM}" = "linux" ]; then
    ${QT_PATH}/bin/qmake ../green.pro CONFIG+=x86_64 ${GREEN_QMAKE_CONFIG}
elif [ "${GREENPLATFORM}" = "windows" ]; then
    ${QT_PATH}/bin/qmake -spec win32-g++ ../green.pro CONFIG+=x86_64 TARGET_BIT=m64 ${GREEN_QMAKE_CONFIG}
elif [ "${GREENPLATFORM}" = "osx" ]; then
    ${QT_PATH}/bin/qmake ../green.pro -spec macx-clang CONFIG+=x86_64 QMAKE_MACOSX_DEPLOYMENT_TARGET=10.14 ${GREEN_QMAKE_CONFIG}
fi

make -j${NUM_JOBS}

if [ "${GREENSYMBOLS}" = "" ]; then
   if [ "${GREENPLATFORM}" = "linux" ]; then
       python ../tools/symbol-check.py < ${BUILDROOT}/Green
       strip ${BUILDROOT}/Green
   elif [ "${GREENPLATFORM}" = "windows" ]; then
       x86_64-w64-mingw32-strip ${BUILDROOT}/Green.exe
   elif [ "${GREENPLATFORM}" = "osx" ]; then
       strip ${BUILDROOT}/Green.app/Contents/MacOS/Green
   fi
fi
