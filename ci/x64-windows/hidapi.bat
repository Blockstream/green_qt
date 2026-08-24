@echo off
setlocal enabledelayedexpansion

set FILENAME=hidapi-0.15.0
set ARCHIVE=%FILENAME%.tar.gz
set HASH=5d84dec684c27b97b921d2f3b73218cb773cf4ea915caee317ac8fc73cef8136

curl -s -L -o %ARCHIVE% https://github.com/libusb/hidapi/archive/refs/tags/%ARCHIVE%

certutil -hashfile %ARCHIVE% SHA256 | findstr /i /c:"%HASH%" >nul
if errorlevel 1 (
    echo Checksum verification failed for %ARCHIVE%
    exit /b 1
)

7z x %ARCHIVE% -so | 7z x -si -ttar

cmake -S hidapi-%FILENAME% -B hidapi-bld ^
    -DBUILD_SHARED_LIBS=FALSE ^
    -DHIDAPI_BUILD_HIDTEST=OFF

cmake --build hidapi-bld --config Release

cmake --install hidapi-bld --strip --prefix %PREFIX% || exit /b 1

:: Keep the layer small -- nothing after this step needs the source or build tree.
del /q %ARCHIVE%
rmdir /s /q hidapi-%FILENAME%
rmdir /s /q hidapi-bld

endlocal
