#!/bin/bash
set -eo pipefail

. tools/envs.env $1 $2

./tools/builddeps.sh $1 $2

CURRENTDIR=${PWD}

cd ${BUILDROOT}

GREEN_QMAKE_CONFIG="CONFIG+=release CONFIG+=qml_release CONFIG+=static QMAKE_CXXFLAGS_RELEASE+=-flto QMAKE_LDFLAGS_RELEASE+=-flto"

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
       python ${CURRENTDIR}/tools/symbol-check.py < ${BUILDROOT}/Green
       strip ${BUILDROOT}/Green
   elif [ "${GREENPLATFORM}" = "windows" ]; then
       x86_64-w64-mingw32-strip ${BUILDROOT}/release/Green.exe
   elif [ "${GREENPLATFORM}" = "osx" ]; then
       strip ${BUILDROOT}/Green.app/Contents/MacOS/Green
   fi
fi

if [ "${GREENPLATFORM}" = "linux" ]; then
   ${CURRENTDIR}/tools/appimage.sh ${CURRENTDIR}
fi
