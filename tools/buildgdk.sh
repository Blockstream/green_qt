#!/bin/bash
set -eo pipefail

GDK_REPO=https://github.com/Blockstream/gdk.git
GDK_BRANCH=release_0.73.2
GDK_COMMIT=b1cfb97ae72df23168bd32622fae8449b7e5c9ff

mkdir -p build

cd build

if [ ! -d gdk ]; then
    git clone --quiet --depth 1 --branch $GDK_BRANCH --single-branch $GDK_REPO gdk
fi

cd gdk
git rev-parse HEAD
git checkout $GDK_COMMIT

# unset to disable building gdk java support
unset JAVA_HOME
# unset because it clashes with gdk build script
unset CMAKE_TOOLCHAIN_FILE

python3 -m venv .venv
source .venv/bin/activate
pip install -r tools/requirements.txt
pip install setuptools

if [ "$HOST" = "linux" ]; then
    tools/build.sh --gcc --buildtype release --static --install $PREFIX --parallel 8
elif [ "$HOST" = "windows" ]; then
    tools/build.sh --mingw-w64 --buildtype release --static --install $PREFIX --parallel 8
elif [ "$HOST" = "macos" ]; then
    tools/build.sh --clang --buildtype release --static --install $PREFIX --parallel 8
else
    exit 1
fi

cp -R build-*/external_deps_build/include/boost $PREFIX/include
cp -R build-*/external_deps_build/include/nlohmann $PREFIX/include
