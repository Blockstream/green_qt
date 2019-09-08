#!/bin/bash
set -eo pipefail

QTBUILD=${BUILDROOT}/qt-release-${QTVERSION}

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
       echo "adf00266dc38352a166a9739f1a24a1e36f1be9c04bf72e16e142a256436974e ${BUILDROOT}/qt-everywhere-src-${QTVERSION}.tar.xz" | sha256sum --check --strict
       $(cd ${BUILDROOT} && \
       tar xf qt-everywhere-src-${QTVERSION}.tar.xz && \
       rm qt-everywhere-src-${QTVERSION}.tar.xz)
   fi
   QTSRCDIR=${BUILDROOT}/qt-everywhere-src-${QTVERSION}
fi

NUM_JOBS=$(cat /proc/cpuinfo | grep ^processor | wc -l)

echo "Qt: building..."
mkdir ${QTBUILD}
cd ${QTSRCDIR}
./configure --recheck-all -opensource -confirm-license \
    -release -static -prefix ${QTBUILD} -nomake tests -nomake examples -no-compile-examples \
    -reduce-relocations -ltcg \
    -qt-xcb -no-zlib -qt-libpng -qt-libjpeg -no-openssl \
    -no-sql-db2 -no-sql-ibase -no-sql-mysql -no-sql-oci -no-sql-odbc -no-sql-psql -no-sql-sqlite -no-sql-sqlite2 -no-sql-tds \
    -no-cups -no-dbus -no-gif -no-feature-xml -no-feature-testlib \
    -skip qt3d -skip qtactiveqt -skip qtandroidextras -skip qtcanvas3d -skip qtcharts -skip qtconnectivity -skip qtdatavis3d -skip qtdoc -skip qtgamepad  \
    -skip qtlocation -skip qtmacextras -skip qtnetworkauth -skip qtpurchasing -skip qtremoteobjects -skip qtscript -skip qtscxml -skip qtsensors -skip qtserialbus -skip qtserialport \
    -skip qtspeech -skip qttools -skip qttranslations -skip qtvirtualkeyboard -skip qtwebchannel -skip qtwebsockets -skip qtwebview -skip qtwinextras -skip qtx11extras -skip qtwebengine > ${QTBUILD}/build.log 2>&1

make -j${NUM_JOBS} >> ${QTBUILD}/build.log 2>&1
make install >> ${QTBUILD}/build.log 2>&1

touch ${QTBUILD}/build.done
