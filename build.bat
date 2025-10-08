setlocal enabledelayedexpansion

call "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvarsall.bat" x64

set PREFIX=C:\deps
set CMAKE_PREFIX_PATH=C:\deps;C:\depends\windows-x86_64

lib /def:C:\depends\windows-x86_64\bin\libgreen_gdk.def /out:C:\depends\windows-x86_64\lib\libgreen_gdk.lib /machine:x64
lib /def:C:\depends\windows-x86_64\bin\libserialport-0.def /out:C:\depends\windows-x86_64\lib\libserialport-0.lib /machine:x64

if /i "%CI_COMMIT_REF_NAME:~0,8%"=="release_" (
    set "GREEN_ENV=Production"
) else (
    set "GREEN_ENV=Testing"
    set "GREEN_BUILD_ID=-%CI_COMMIT_SHORT_SHA%"
)

call C:\qt\6.8.3\msvc2022_64\bin\qt-cmake ^
    -S C:\src -B C:\src\bld ^
    -DCMAKE_BUILD_TYPE=RelWithDebInfo ^
    -DGREEN_ENV=%GREEN_ENV% ^
    -DGREEN_BUILD_ID="%GREEN_BUILD_ID%" ^
    -DGREEN_LOG_FILE=%CI_COMMIT_BRANCH% ^
    -DENABLE_SENTRY=OFF ^
    -DSENTRY_KEY=%SENTRY_KEY%

cmake --build C:\src\bld --config RelWithDebInfo

C:\qt\6.8.3\msvc2022_64\bin\windeployqt.exe --qmldir C:\src\qml C:\src\bld\RelWithDebInfo\blockstream.exe

copy C:\depends\windows-x86_64\bin\libgreen_gdk.dll C:\src\bld\RelWithDebInfo\
copy C:\depends\windows-x86_64\bin\libserialport-0.dll C:\src\bld\RelWithDebInfo\

endlocal
