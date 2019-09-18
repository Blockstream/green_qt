#!/bin/bash
set -eo pipefail

source ./tools/buildenv.sh $1

mkdir -p ${BUILDDIR}

./tools/buildqt.sh || (cat ${QT_PATH}/build.log && false)
echo "Qt: OK"
./tools/buildgdk.sh || (cat ${BUILDROOT}/gdk-${GDKBLDID}/build.log && false)
echo "GDK: OK"

cd ${BUILDROOT}

if [ "${GREENPLATFORM}" = "linux" ]; then
    ${QT_PATH}/bin/qmake ../green.pro CONFIG+=release CONFIG+=x86_64 CONFIG+=qml_release CONFIG+=static QMAKE_CXXFLAGS_RELEASE+=-flto QMAKE_LDFLAGS_RELEASE+=-flto
elif [ "${GREENPLATFORM}" = "windows" ]; then
    ${QT_PATH}/bin/qmake -spec win32-g++ ../green.pro CONFIG+=x86_64 CONFIG+=release CONFIG+=qml_release CONFIG+=static TARGET_BIT=m64
elif [ "${GREENPLATFORM}" = "osx" ]; then
    ${QT_PATH}/bin/qmake ../green.pro -spec macx-clang CONFIG+=x86_64 CONFIG+=release CONFIG+=qml_release CONFIG+=static QMAKE_CXXFLAGS_RELEASE+=-flto QMAKE_LDFLAGS_RELEASE+=-flto QMAKE_MACOSX_DEPLOYMENT_TARGET=10.14
fi

make -j${NUM_JOBS}

if [ "${GREENPLATFORM}" = "linux" ]; then
    python ../tools/symbol-check.py < ${BUILDROOT}/Green
    strip ${BUILDROOT}/Green
elif [ "${GREENPLATFORM}" = "windows" ]; then
    x86_64-w64-mingw32-strip ${BUILDROOT}/release/Green.exe
elif [ "${GREENPLATFORM}" = "osx" ]; then
    strip ${BUILDROOT}/Green.app/Contents/MacOS/Green
fi
