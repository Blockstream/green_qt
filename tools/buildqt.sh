#!/bin/bash
set -eo pipefail


if [ ! -d ${BUILDROOT} ]; then
    echo "BUILDROOT needs to be set to a valid directory"
    exit 1
fi

if [ -f ${QTBUILD}/build.done ]; then
    exit 0
fi

QTSRCDIR=/qt-everywhere-src-${QTVERSION}

if [ ! -d ${QTSRCDIR} ]; then
   if [ ! -d ${BUILDROOT}/qt-everywhere-src-${QTVERSION} ]; then
       echo "Qt: Downloading..."
       curl -sL -o ${BUILDROOT}/qt-everywhere-src-${QTVERSION}.tar.xz https://download.qt.io/archive/qt/${QTMAJOR}/${QTVERSION}/single/qt-everywhere-src-${QTVERSION}.tar.xz
       echo "adf00266dc38352a166a9739f1a24a1e36f1be9c04bf72e16e142a256436974e  ${BUILDROOT}/qt-everywhere-src-${QTVERSION}.tar.xz" | shasum -a 256 --check
       $(cd ${BUILDROOT} && \
       tar xf qt-everywhere-src-${QTVERSION}.tar.xz && \
       rm qt-everywhere-src-${QTVERSION}.tar.xz)
   fi
   QTSRCDIR=${BUILDROOT}/qt-everywhere-src-${QTVERSION}
fi

echo "Qt: building..."
mkdir ${QTBUILD}
cd ${QTSRCDIR}

if [ "${GREENPLATFORM}" = "linux" ]; then
    QTOPTIONS="-reduce-relocations -ltcg -qt-xcb"
elif [ "${GREENPLATFORM}" = "windows" ]; then
    QTOPTIONS="-xplatform win32-g++ -device-option CROSS_COMPILE=/usr/bin/x86_64-w64-mingw32- -skip qtwayland -opengl desktop"
elif [ "${GREENPLATFORM}" = "osx" ]; then
    QTOPTIONS="-skip qtwayland -ltcg"
fi

./configure --recheck-all -opensource -confirm-license \
    ${QTOPTIONS} -release -static -prefix ${QTBUILD} -nomake tests -nomake examples -no-compile-examples \
    -no-zlib -qt-libpng -qt-libjpeg -no-openssl \
    -no-sql-db2 -no-sql-ibase -no-sql-mysql -no-sql-oci -no-sql-odbc -no-sql-psql -no-sql-sqlite -no-sql-sqlite2 -no-sql-tds \
    -no-cups -no-dbus -no-gif -no-feature-testlib \
    -skip qt3d -skip qtactiveqt -skip qtandroidextras -skip qtcanvas3d -skip qtcharts -skip qtconnectivity -skip qtdatavis3d -skip qtdoc -skip qtgamepad  \
    -skip qtlocation -skip qtmacextras -skip qtnetworkauth -skip qtpurchasing -skip qtremoteobjects -skip qtscript -skip qtscxml -skip qtsensors -skip qtserialbus -skip qtserialport \
    -skip qtspeech -skip qttranslations -skip qtvirtualkeyboard -skip qtwebchannel -skip qtwebsockets -skip qtwebview -skip qtwinextras -skip qtx11extras -skip qtwebengine > ${QTBUILD}/build.log 2>&1

make -j${NUM_JOBS} >> ${QTBUILD}/build.log 2>&1
make install >> ${QTBUILD}/build.log 2>&1


if [ "${GREENPLATFORM}" = "osx" ]; then
    rm -rf ${QTBUILD}/qml/Qt/labs/lottieqt
fi

touch ${QTBUILD}/build.done
