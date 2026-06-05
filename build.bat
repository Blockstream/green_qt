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

call C:\qt\6.11.1\msvc2022_64\bin\qt-cmake ^
    -S C:\src -B C:\src\bld ^
    -G "Ninja Multi-Config" ^
    -DCMAKE_BUILD_TYPE=RelWithDebInfo ^
    -DCMAKE_CXX_FLAGS="/FS" ^
    -DGREEN_ENV=%GREEN_ENV% ^
    -DGREEN_BUILD_ID="%GREEN_BUILD_ID%" ^
    -DGREEN_LOG_FILE=%CI_COMMIT_BRANCH% ^
    -DENABLE_SENTRY=OFF ^
    -DSENTRY_KEY=%SENTRY_KEY% || exit /b !errorlevel!

cmake --build C:\src\bld --config RelWithDebInfo --parallel 4 || exit /b !errorlevel!

C:\qt\6.11.1\msvc2022_64\bin\windeployqt.exe --qmldir C:\src\qml C:\src\bld\RelWithDebInfo\blockstream.exe || exit /b !errorlevel!

copy C:\depends\windows-x86_64\bin\libgreen_gdk.dll C:\src\bld\RelWithDebInfo\ || exit /b !errorlevel!
copy C:\depends\windows-x86_64\bin\libserialport-0.dll C:\src\bld\RelWithDebInfo\ || exit /b !errorlevel!

endlocal
