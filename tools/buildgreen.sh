#!/bin/bash
set -eo pipefail

. tools/envs.env $1 $2

./tools/builddeps.sh $1 $2

CURRENTDIR=${PWD}
QZXING_PATH=${BUILDROOT}/qzxing

cd ${BUILDROOT}

GREEN_QMAKE_CONFIG="CONFIG+=release CONFIG+=qml_release CONFIG+=static GDK_PATH=${GDK_PATH} QZXING_PATH=${QZXING_PATH}"

if [ "${GREENSYMBOLS}" != "" ]; then
    GREEN_QMAKE_CONFIG+=" QMAKE_CXXFLAGS+=-g"
fi

if [ "${GREENPLATFORM}" = "linux" ]; then
    ${QT_PATH}/bin/qmake ${CURRENTDIR}/green.pro CONFIG+=x86_64 ${GREEN_QMAKE_CONFIG}
elif [ "${GREENPLATFORM}" = "windows" ]; then
    ${QT_PATH}/bin/qmake -spec win32-g++ ${CURRENTDIR}/green.pro CONFIG+=x86_64 TARGET_BIT=m64 ${GREEN_QMAKE_CONFIG}
elif [ "${GREENPLATFORM}" = "osx" ]; then
    ${QT_PATH}/bin/qmake ${CURRENTDIR}/green.pro -spec macx-clang CONFIG+=x86_64 QMAKE_MACOSX_DEPLOYMENT_TARGET=10.14 ${GREEN_QMAKE_CONFIG}
fi

make -j${NUM_JOBS}

if [ "${GREENSYMBOLS}" = "" ]; then
   if [ "${GREENPLATFORM}" = "linux" ]; then
       python ${CURRENTDIR}/tools/symbol-check.py < ${BUILDROOT}/green
       strip ${BUILDROOT}/green
   elif [ "${GREENPLATFORM}" = "windows" ]; then
       x86_64-w64-mingw32-strip ${BUILDROOT}/release/green.exe
   elif [ "${GREENPLATFORM}" = "osx" ]; then
       strip ${BUILDROOT}/green.app/Contents/MacOS/green
   fi
fi

if [ "${GREENPLATFORM}" = "linux" ]; then
    ${CURRENTDIR}/tools/appimage.sh ${CURRENTDIR}
fi
