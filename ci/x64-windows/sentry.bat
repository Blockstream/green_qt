setlocal enabledelayedexpansion

set SENTRY_REPO=https://github.com/getsentry/sentry-native
set SENTRY_TAG=0.17.1
set SENTRY_COMMIT=620f6afda74c32a7c1468200a2578f62a8006277

rem Staged into the image by the Dockerfile, from tools/patches.
set PATCHES=C:\patches

git clone --recurse-submodules --branch %SENTRY_TAG% --single-branch %SENTRY_REPO% sentry-native-src || exit /b 1

cd sentry-native-src
git rev-parse HEAD
git checkout %SENTRY_COMMIT% || exit /b 1
git submodule update --init --recursive || exit /b 1
cd ..

rem Keep secrets out of the minidumps we upload; see the patch headers.
for %%p in (%PATCHES%\*.patch) do (
    git -C sentry-native-src\external\crashpad apply --ignore-whitespace "%%p" || exit /b 1
)

call \qt\6.12.0\msvc2022_64\bin\qt-cmake -S sentry-native-src -B sentry-native-bld ^
    -DCMAKE_BUILD_TYPE=RelWithDebInfo ^
    -DSENTRY_BACKEND=crashpad ^
    -DCRASHPAD_ENABLE_STACKTRACE=ON ^
    -DSENTRY_INTEGRATION_QT=OFF ^
    -DSENTRY_BUILD_SHARED_LIBS=OFF ^
    -DSENTRY_BUILD_EXAMPLES=OFF ^
    -DSENTRY_BUILD_TESTS=OFF

cmake --build sentry-native-bld --config RelWithDebInfo

cmake --install sentry-native-bld --strip --prefix %PREFIX% --config RelWithDebInfo || exit /b 1

:: Keep the layer small -- nothing after this step needs the source or build tree.
rmdir /s /q sentry-native-src
rmdir /s /q sentry-native-bld

endlocal
