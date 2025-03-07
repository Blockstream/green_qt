#!/bin/bash
set -exo pipefail

OPTIONS="--prefix $PREFIX --enable-static --disable-shared"

if [ "$HOST" = "windows" ]; then
    OPTIONS="$OPTIONS --host=x86_64-w64-mingw32"
fi

mkdir -p build && cd build

wget https://gnupg.org/ftp/gcrypt/libgpg-error/libgpg-error-1.51.tar.bz2
tar -xjf libgpg-error-1.51.tar.bz2
cd libgpg-error-1.51
./configure $OPTIONS --disable-tests
make install
cd ..

wget https://gnupg.org/ftp/gcrypt/libassuan/libassuan-3.0.2.tar.bz2
tar -xjf libassuan-3.0.2.tar.bz2
cd libassuan-3.0.2
./configure $OPTIONS
make install
cd ..

wget https://gnupg.org/ftp/gcrypt/gpgme/gpgme-1.24.2.tar.bz2
tar -xjf gpgme-1.24.2.tar.bz2
cd gpgme-1.24.2
./configure $OPTIONS \
  --disable-glibtest \
  --disable-gpg-test \
  --disable-gpgconf-test \
  --disable-gpgsm-test \
  --disable-g13-test \
  --enable-languages=
make install
