#!/bin/bash
set -eo pipefail

mkdir -p build

cd build

if [ ! -d gdk ]; then
    git clone --quiet --depth 1 --branch release_0.68.4 --single-branch https://github.com/Blockstream/gdk.git gdk
fi

cd gdk
git rev-parse HEAD

# unset to disable building gdk java support
unset JAVA_HOME
# unset because it clashes with gdk build script
unset CMAKE_TOOLCHAIN_FILE

python3 -m venv .venv
source .venv/bin/activate
pip install -r tools/requirements.txt

if [ "$HOST" = "linux" ]; then
    tools/build.sh --gcc --buildtype release --install $PREFIX --parallel 8
elif [ "$HOST" = "windows" ]; then
    tools/build.sh --mingw-w64 --buildtype release --install $PREFIX --parallel 8
elif [ "$HOST" = "macos" ]; then
    tools/build.sh --clang --buildtype release --install $PREFIX --parallel 8
else
    exit 1
fi

cp -R */external_deps_build/boost/build/include/boost $PREFIX/include
cp -R */external_deps_build/nlohmann_json/include/nlohmann $PREFIX/include
