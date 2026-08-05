#!/bin/bash
set -exo pipefail

OPTIONS="--prefix $PREFIX --enable-static --disable-shared"

if [ "$HOST" = "windows" ]; then
    OPTIONS="$OPTIONS --host=x86_64-w64-mingw32"
fi

mkdir -p build && cd build

LIBGPG_ERROR_HASH=be0f1b2db6b93eed55369cdf79f19f72750c8c7c39fc20b577e724545427e6b2
wget https://gnupg.org/ftp/gcrypt/libgpg-error/libgpg-error-1.51.tar.bz2
echo "${LIBGPG_ERROR_HASH}  libgpg-error-1.51.tar.bz2" | ${SHA256SUM:-sha256sum} --check
tar -xjf libgpg-error-1.51.tar.bz2
cd libgpg-error-1.51
./configure $OPTIONS --disable-tests
make install
cd ..

LIBASSUAN_HASH=d2931cdad266e633510f9970e1a2f346055e351bb19f9b78912475b8074c36f6
wget https://gnupg.org/ftp/gcrypt/libassuan/libassuan-3.0.2.tar.bz2
echo "${LIBASSUAN_HASH}  libassuan-3.0.2.tar.bz2" | ${SHA256SUM:-sha256sum} --check
tar -xjf libassuan-3.0.2.tar.bz2
cd libassuan-3.0.2
./configure $OPTIONS
make install
cd ..

GPGME_HASH=e11b1a0e361777e9e55f48a03d89096e2abf08c63d84b7017cfe1dce06639581
wget https://gnupg.org/ftp/gcrypt/gpgme/gpgme-1.24.2.tar.bz2
echo "${GPGME_HASH}  gpgme-1.24.2.tar.bz2" | ${SHA256SUM:-sha256sum} --check
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
