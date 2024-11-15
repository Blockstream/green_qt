#!/bin/bash
set -eo pipefail

mkdir -p build

cd build

curl -s -L -o icu4c-76_1-src.tgz https://github.com/unicode-org/icu/releases/download/release-76-1/icu4c-76_1-src.tgz

tar zxf icu4c-76_1-src.tgz

cd icu/source

./configure --prefix=$PREFIX --disable-shared --enable-static

make

make install
