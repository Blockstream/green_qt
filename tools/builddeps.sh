#!/bin/bash
set -eo pipefail

. tools/envs.env $1

if [ "${BUILDDIR}" = "" ]; then
    echo "Unsupported target"
    exit 1
fi

mkdir -p ${BUILDDIR}

QZXING_COMMIT=8bed4366748d995011e7e8b25671b37d4feb783f
QZXING_BRANCH=mirror

git clone --quiet --single-branch ${QZXING_BRANCH} https://github.com/Blockstream/qzxing.git ${BUILDDIR}/qzxing &&(cd ${BUILDDIR}/qzxing && git checkout ${QZXING_COMMIT})

./tools/buildqt.sh || (cat ${QT_PATH}/build.log && false)
echo "Qt: OK"
./tools/buildgdk.sh || (cat ${GDK_PATH}/build.log && false)
echo "GDK: OK"

cd ${BUILDROOT}


GREEN_QMAKE_CONFIG="CONFIG+=release CONFIG+=qml_release CONFIG+=static QMAKE_CXXFLAGS_RELEASE+=-flto QMAKE_LDFLAGS_RELEASE+=-flto"

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
       x86_64-w64-mingw32-strip ${BUILDROOT}/release/Green.exe
   elif [ "${GREENPLATFORM}" = "osx" ]; then
       strip ${BUILDROOT}/Green.app/Contents/MacOS/Green
   fi
fi

if [ "${GREENPLATFORM}" = "linux" ]; then
   ../tools/appimage.sh
fi
