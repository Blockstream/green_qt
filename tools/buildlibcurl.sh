#!/bin/bash
set -eo pipefail

COMMIT=400fffa90f30c7a2dc762fa33009d24851bd2016 # curl-8_17_0

mkdir -p build && cd build

git clone https://github.com/curl/curl.git curl-src

(cd curl-src && git checkout $COMMIT && git rev-parse HEAD)

curl_common=(
  -DCMAKE_BUILD_TYPE=Release
  -DBUILD_CURL_EXE=OFF
  -DCURL_DISABLE_LDAP=ON
  -DCURL_USE_LIBPSL=OFF
  -DOPENSSL_USE_STATIC_LIBS=ON
)

# Static libcurl: linked into the app and the sentry SDK (this is the build
# sentry's CMake finds via find_package(CURL)).
cmake -S curl-src -B curl-bld "${curl_common[@]}" \
  -DBUILD_SHARED_LIBS=OFF \
  -DCURL_STATICLIB=ON
cmake --build curl-bld
cmake --install curl-bld --strip --prefix $PREFIX

# Shared libcurl: crashpad's Linux HTTP uploader dlopen()s libcurl.so.4 at
# runtime to POST minidumps, so a shared library must be shipped alongside
# crashpad_handler. Install to a temp prefix and copy only the .so into
# $PREFIX/lib, leaving the static CMake/pkg-config package above untouched.
cmake -S curl-src -B curl-bld-shared "${curl_common[@]}" \
  -DBUILD_SHARED_LIBS=ON
cmake --build curl-bld-shared
cmake --install curl-bld-shared --strip --prefix "$PWD/curl-shared"
cp -a curl-shared/lib/libcurl.so* $PREFIX/lib/
