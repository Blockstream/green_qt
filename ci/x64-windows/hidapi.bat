@echo off
setlocal enabledelayedexpansion

set FILENAME=hidapi-0.14.0
set ARCHIVE=%FILENAME%.tar.gz

curl -s -L -o %ARCHIVE% https://github.com/libusb/hidapi/archive/refs/tags/%ARCHIVE%

7z x %ARCHIVE% -so | 7z x -si -ttar

cmake -S hidapi-%FILENAME% -B hidapi-bld ^
    -DBUILD_SHARED_LIBS=FALSE ^
    -DHIDAPI_BUILD_HIDTEST=OFF

cmake --build hidapi-bld --config Release

cmake --install hidapi-bld --strip --prefix %PREFIX%

endlocal
