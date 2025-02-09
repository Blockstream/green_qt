#!/bin/bash
set -eo pipefail

mkdir -p build && cd build

git clone https://github.com/curl/curl.git curl-src

(cd curl-src && git rev-parse HEAD)

cmake -S curl-src -B curl-bld \
  -DCMAKE_BUILD_TYPE=Release \
  -DBUILD_CURL_EXE=OFF \
  -DBUILD_SHARED_LIBS=OFF \
  -DCURL_STATICLIB=ON \
  -DCURL_DISABLE_LDAP=ON \
  -DCURL_USE_LIBPSL=OFF \
  -DOPENSSL_USE_STATIC_LIBS=ON

cmake --build curl-bld
cmake --install curl-bld --strip --prefix $PREFIX
