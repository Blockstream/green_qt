#!/bin/bash
set -exo pipefail

SENTRY_REPO=https://github.com/getsentry/sentry-native
SENTRY_TAG=0.15.4
SENTRY_COMMIT=a1827544e2da7e50517615003288c25380f8d457

PATCHES=$(cd "$(dirname "$0")/patches" && pwd)

mkdir -p build && cd build && rm -rf sentry-native-src

git clone --recurse-submodules --quiet --branch $SENTRY_TAG --single-branch $SENTRY_REPO sentry-native-src

(cd sentry-native-src && git rev-parse HEAD && git checkout $SENTRY_COMMIT && git submodule update --init --recursive)

# Keep secrets out of the minidumps we upload; see the patch headers.
for patch in "$PATCHES"/*.patch; do
    git -C sentry-native-src/external/crashpad apply --ignore-whitespace "$patch"
done

qt-cmake -S sentry-native-src -B sentry-native-bld \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DCMAKE_OSX_DEPLOYMENT_TARGET=12.0 \
    -DSENTRY_BACKEND=crashpad \
    -DCRASHPAD_ENABLE_STACKTRACE=ON \
    -DSENTRY_INTEGRATION_QT=OFF \
    -DSENTRY_BUILD_SHARED_LIBS=OFF \
    -DSENTRY_BUILD_EXAMPLES=OFF \
    -DSENTRY_BUILD_TESTS=OFF

cmake --build sentry-native-bld --config RelWithDebInfo

cmake --install sentry-native-bld --strip --prefix $PREFIX
