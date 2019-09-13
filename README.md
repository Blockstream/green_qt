# Blockstream Green

Build status: [![Build Status](https://travis-ci.org/Blockstream/green_qt.png?branch=master)](https://travis-ci.org/Blockstream/green_qt)


## Build on macOS


Build Qt 5.13.1:
```sh
wget https://download.qt.io/official_releases/qt/5.13/5.13.1/single/qt-everywhere-src-5.13.1.tar.xz
tar xf qt-everywhere-src-5.13.1.tar.xz
cd qt-everywhere-src-5.13.1

./configure --recheck-all -opensource -confirm-license \
    -release -static -prefix ../build/qt -nomake tests -nomake examples -no-compile-examples \
    -qt-zlib -qt-libpng -qt-libjpeg \
    -no-sql-db2 -no-sql-ibase -no-sql-mysql -no-sql-oci -no-sql-odbc -no-sql-psql -no-sql-sqlite -no-sql-sqlite2 -no-sql-tds \
    -no-cups -no-dbus -no-gif -no-feature-xml -no-feature-testlib \
    -skip qt3d -skip qtactiveqt -skip qtandroidextras -skip qtcanvas3d -skip qtcharts -skip qtconnectivity -skip qtdatavis3d -skip qtdoc -skip qtgamepad  \
    -skip qtlocation -skip qtmacextras -skip qtnetworkauth -skip qtpurchasing -skip qtremoteobjects -skip qtscript -skip qtscxml -skip qtsensors -skip qtserialbus -skip qtserialport \
    -skip qtspeech -skip qttools -skip qttranslations -skip qtvirtualkeyboard -skip qtwayland -skip qtwebchannel -skip qtwebsockets -skip qtwebview -skip qtwinextras -skip qtx11extras -skip qtwebengine

make
make install
```

Build Green
```sh
git submodule init
git submodule update --remote
mkdir build
cd build
$QT_PATH/bin/qmake ../green.pro -spec macx-clang CONFIG+=debug CONFIG+=x86_64 CONFIG+=qml_debug
make qmake_all
```
