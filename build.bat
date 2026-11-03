setlocal enabledelayedexpansion

call "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvarsall.bat" x64 || exit /b !errorlevel!

set PREFIX=C:\deps
set CMAKE_PREFIX_PATH=C:\deps;C:\depends\windows-x86_64

lib /def:C:\depends\windows-x86_64\bin\libgreen_gdk.def /out:C:\depends\windows-x86_64\lib\libgreen_gdk.lib /machine:x64 || exit /b !errorlevel!
lib /def:C:\depends\windows-x86_64\bin\libserialport-0.def /out:C:\depends\windows-x86_64\lib\libserialport-0.lib /machine:x64 || exit /b !errorlevel!

if /i "%CI_COMMIT_REF_NAME:~0,8%"=="release_" (
    set "GREEN_ENV=Production"
) else (
    set "GREEN_ENV=Testing"
    set "GREEN_BUILD_ID=-%CI_COMMIT_SHORT_SHA%"
)

REM ccache is fetched per build instead of baked into the image; bump version and hash together
set CCACHE_VERSION=4.14.2
set CCACHE_SHA256=6993ce645e53192cec592ee23186200b574ac4c59097ecde8d9cfd681b47ae84
curl -sSfL -o C:\ccache.zip https://github.com/ccache/ccache/releases/download/v!CCACHE_VERSION!/ccache-!CCACHE_VERSION!-windows-x86_64.zip || exit /b !errorlevel!
powershell -NoProfile -Command "if ((Get-FileHash C:\ccache.zip -Algorithm SHA256).Hash -ne $env:CCACHE_SHA256) { exit 1 }" || exit /b 1
tar -xf C:\ccache.zip -C C:\ || exit /b !errorlevel!
set "PATH=C:\ccache-!CCACHE_VERSION!-windows-x86_64;!PATH!"

cd /d C:\src || exit /b !errorlevel!
call C:\qt\6.12.0\msvc2022_64\bin\qt-cmake --preset ci-windows || exit /b !errorlevel!

ccache -z

cmake --build C:\src\bld --config RelWithDebInfo --parallel 4 || exit /b !errorlevel!

ccache -s

C:\qt\6.12.0\msvc2022_64\bin\windeployqt.exe --qmldir C:\src\qml C:\src\bld\RelWithDebInfo\blockstream.exe || exit /b !errorlevel!

copy C:\depends\windows-x86_64\bin\libgreen_gdk.dll C:\src\bld\RelWithDebInfo\ || exit /b !errorlevel!
copy C:\depends\windows-x86_64\bin\libserialport-0.dll C:\src\bld\RelWithDebInfo\ || exit /b !errorlevel!

REM sentry-native crashpad backend handler + WER module, shipped next to blockstream.exe.
REM crashpad_wer.dll lets crashpad capture fast-fail/non-SEH crashes (abort, heap
REM corruption, 0xC0000409); sentry-native auto-registers it from the handler's dir.
copy C:\deps\bin\crashpad_handler.exe C:\src\bld\RelWithDebInfo\ || exit /b !errorlevel!
copy C:\deps\bin\crashpad_wer.dll C:\src\bld\RelWithDebInfo\ || exit /b !errorlevel!

endlocal
