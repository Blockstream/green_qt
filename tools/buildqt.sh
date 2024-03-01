#!/bin/bash
set -eox pipefail

QT_MAJOR=6.5
QT_VERSION=${QT_MAJOR}.3
QT_HASH=7cda4d119aad27a3887329cfc285f2aba5da85601212bcb0aea27bd6b7b544cb
QT_BASENAME=qt-everywhere-src-${QT_VERSION}
QT_FILENAME=${QT_BASENAME}.tar.xz

mkdir -p build
cd build

if [ ! -d $QT_BASENAME ]; then
    if [ ! -f $QT_FILENAME ]; then
        echo "qt: downloading"
        wget https://mirrors.ocf.berkeley.edu/qt/official_releases/qt/${QT_MAJOR}/${QT_VERSION}/single/${QT_FILENAME}

        echo "qt: verifying"
        echo "${QT_HASH}  ${QT_FILENAME}" | ${SHA256SUM:-sha256sum} --check
    fi

    echo "qt: extracting"
    tar xf ${QT_FILENAME}

    echo "qt: patching"
    cd $QT_BASENAME
    patch -p1 < ../../tools/patches/fix-wmf.diff
    rm -rf qtwebengine
    cd ..
fi

if [[ "$HOST" == "windows" ]]; then
    if [ ! -d windows ]; then
        _CMAKE_TOOLCHAIN_FILE=$CMAKE_TOOLCHAIN_FILE
        _QT_HOST_PATH=$QT_HOST_PATH
        unset QT_HOST_PATH
        unset CMAKE_TOOLCHAIN_FILE
        mkdir windows
        cd windows

        echo "qt: configuring native"
        ../$QT_BASENAME/configure \
            -release \
            -static -static-runtime \
            -prefix $_QT_HOST_PATH \
            -skip qt3d,qt5compat,qtactiveqt,qtcharts,qtcoap,qtconnectivity,qtdatavis3d,qtdoc,qthttpserver,qtimageformats,qtlanguageserver,qtlottie,qtmqtt,qtmultimedia,qtnetworkauth,qtopcua,qtpositioning,qtquick3d,qtquick3dphysics,qtquicktimeline,qtremoteobjects,qtscxml,qtsensors,qtserialbus,qtserialport,qtspeech,qtsvg,qttranslations,qtvirtualkeyboard,qtwayland,qtwebchannel,qtwebsockets,qtwebview,qtlocation \
            -no-feature-sql -no-feature-sql-sqlite \
            -nomake tests -nomake examples

        echo "qt: building native"
        cmake --build . --parallel --target install

        export CMAKE_TOOLCHAIN_FILE=$_CMAKE_TOOLCHAIN_FILE
        export QT_HOST_PATH=$_QT_HOST_PATH
	      cd ..
    fi
fi

rm -rf linux
mkdir linux
cd linux

echo "qt: configuring"
../$QT_BASENAME/configure \
  -release \
  -static -static-runtime \
  -prefix $PREFIX \
  -skip qt3d,qtactiveqt,qtcharts,qtcoap,qtdatavis3d,qtdoc,qthttpserver,qtlanguageserver,qtlottie,qtmqtt,qtnetworkauth,qtopcua,qtpositioning,qtquick3d,qtquick3dphysics,qtquicktimeline,qtremoteobjects,qtscxml,qtsensors,qtserialbus,qtspeech,qtvirtualkeyboard,qtwebchannel,qtwebsockets,qtwebview,qtlocation \
  -no-feature-sql -no-feature-sql-sqlite \
  -nomake tests -nomake examples

echo "qt: building"
cmake --build . --parallel --target install

echo "qt: done"
