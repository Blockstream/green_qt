#!/bin/bash
set -eo pipefail

mkdir -p build

cd build

if [ ! -d gdk ]; then
    git clone --quiet --depth 1 --branch release_0.0.58 --single-branch https://github.com/Blockstream/gdk.git gdk
fi

cd gdk

# unset to disable building gdk java support
unset JAVA_HOME
# unset because it clashes with gdk build script
unset CMAKE_TOOLCHAIN_FILE

virtualenv -p python3 .venv
source .venv/bin/activate
pip install -r tools/requirements.txt

if [ "$HOST" = "linux" ]; then
    tools/build.sh --gcc
elif [ "$HOST" = "windows" ]; then
    tools/build.sh --mingw-w64
elif [ "$HOST" = "macos" ]; then
    tools/build.sh --clang
else
    exit 1
fi

mkdir -p $PREFIX/include $PREFIX/lib

cp -R  build-*/src/libgreenaddress* $PREFIX/lib
cp -R  build-*/external_deps_build/libwally-core/build/include/* $PREFIX/include
cp -R  build-*/external_deps_build/nlohmann_json/include/nlohmann $PREFIX/include
cp -R  build-*/external_deps_build/boost/build/include/boost $PREFIX/include
cp -R  include/*.h $PREFIX/include
