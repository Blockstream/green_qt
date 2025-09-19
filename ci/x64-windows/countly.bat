@echo off
setlocal enabledelayedexpansion

set COUNTLY_REPO=https://github.com/blockstream/countly-sdk-cpp
set COUNTLY_BRANCH=green_qt
set COUNTLY_COMMIT=fdbf11eea8868fcd41196f0f90cb58296673820a

git clone --recurse-submodules --quiet --depth 1 --branch %COUNTLY_BRANCH% --single-branch %COUNTLY_REPO% countly-src

cd countly-src
git rev-parse HEAD
git checkout %COUNTLY_COMMIT%
cd ..

cmake -S countly-src -B countly-bld ^
    -DBUILD_SHARED_LIBS=OFF ^
    -DCOUNTLY_BUILD_TESTS=OFF ^
    -DCOUNTLY_USE_SQLITE=OFF ^
    -DCOUNTLY_USE_CUSTOM_HTTP=ON ^
    -DCOUNTLY_USE_CUSTOM_SHA256=ON

cmake --build countly-bld --config Release

cmake --install countly-bld --strip --prefix %PREFIX%

endlocal
