@echo off
setlocal enabledelayedexpansion

REM Phase 2 of Windows build: Build app and native deps on Windows.
REM Run from "x64 Native Tools Command Prompt for VS 2022" or this script will
REM try to load the VS environment automatically.
REM
REM Supports resume: run again to continue from the last failed step.
REM Use --restart to clear state and start from scratch.
REM Use --debug to echo each command

set RESTART=0
if "%1"=="--debug" set _DEBUG=1
if "%2"=="--debug" set _DEBUG=1
if "%1"=="--restart" set RESTART=1
if "%2"=="--restart" set RESTART=1
if defined _DEBUG (
    echo DEBUG: Echoing commands. The line printed right before ". non atteso." is the one that fails.
    echo on
)

set STATE_FILE=build_state_windows_phase2
set DEPENDS_PREFIX=C:\depends\windows-x86_64
set PREFIX=C:\deps
REM Try Build Tools first, then Community/Professional/Enterprise
set VSVARS=
if exist "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvarsall.bat" (
    set VSVARS="C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvarsall.bat"
) else if exist "C:\Program Files (x86)\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvarsall.bat" (
    set VSVARS="C:\Program Files (x86)\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvarsall.bat"
) else if exist "C:\Program Files (x86)\Microsoft Visual Studio\2022\Professional\VC\Auxiliary\Build\vcvarsall.bat" (
    set VSVARS="C:\Program Files (x86)\Microsoft Visual Studio\2022\Professional\VC\Auxiliary\Build\vcvarsall.bat"
) else if exist "C:\Program Files (x86)\Microsoft Visual Studio\2022\Enterprise\VC\Auxiliary\Build\vcvarsall.bat" (
    set VSVARS="C:\Program Files (x86)\Microsoft Visual Studio\2022\Enterprise\VC\Auxiliary\Build\vcvarsall.bat"
) else (
    set VSVARS=
)

REM Allow override via environment
if defined WINDOWS_DEPENDS_PREFIX set DEPENDS_PREFIX=%WINDOWS_DEPENDS_PREFIX%
if defined WINDOWS_DEPS_PREFIX set PREFIX=%WINDOWS_DEPS_PREFIX%
if not defined QT_ROOT set QT_ROOT=C:\qt\6.11.1\msvc2022_64

REM Read last completed step
set LAST_STEP=0
if exist %STATE_FILE% (
    if %RESTART%==0 (
        set /p LAST_STEP=<%STATE_FILE%
        if "!LAST_STEP!"=="" set LAST_STEP=0
        echo Resuming from step !LAST_STEP!+1...
    ) else (
        del %STATE_FILE%
        echo Starting fresh build (--restart)
    )
)

REM Load VS environment if not already in a VS prompt
where cl >nul 2>&1
if errorlevel 1 (
    if "!VSVARS!"=="" (
        echo ERROR: Visual Studio not found. Install VS 2022 Build Tools or Visual Studio with C++ workload.
        exit /b 1
    )
    echo Loading Visual Studio environment...
    call !VSVARS! x64
    if errorlevel 1 (
        echo ERROR: Failed to load Visual Studio environment.
        exit /b 1
    )
)

REM Rust is required for the native LWK and GLSDK build steps.
where cargo >nul 2>&1
if errorlevel 1 (
    echo ERROR: Rust not found.
    exit /b 1
)

where rustc >nul 2>&1
if errorlevel 1 (
    echo ERROR: Rust compiler not found.
    exit /b 1
)

REM Validate paths
if not exist "%DEPENDS_PREFIX%\bin\libgreen_gdk.dll" (
    echo ERROR: Phase 1 artifacts not found at %DEPENDS_PREFIX%
    echo Run doc/windows/build-dependencies.sh on Linux first, then copy artifacts to this location.
    exit /b 1
)

if not exist "%QT_ROOT%\bin\qt-cmake.bat" if not exist "%QT_ROOT%\bin\qt-cmake.exe" (
    echo ERROR: Qt not found at %QT_ROOT%
    echo Set QT_ROOT or install Qt 6.11.1 for MSVC 2022 64-bit.
    exit /b 1
)

cd /d "%~dp0\..\.."

REM --- Step 1: Create .lib from .def ---
if %LAST_STEP% LSS 1 (
    echo.
    echo [Step 1/11] Creating import libraries from .def files...
    lib /def:%DEPENDS_PREFIX%\bin\libgreen_gdk.def /out:%DEPENDS_PREFIX%\lib\libgreen_gdk.lib /machine:x64
    if errorlevel 1 goto :fail
    lib /def:%DEPENDS_PREFIX%\bin\libserialport-0.def /out:%DEPENDS_PREFIX%\lib\libserialport-0.lib /machine:x64
    if errorlevel 1 goto :fail
    (echo 1)>%STATE_FILE%
    set LAST_STEP=1
)

REM --- Step 2: Build Countly ---
if %LAST_STEP% LSS 2 (
    echo.
    echo [Step 2/11] Building Countly...
    set PREFIX=%PREFIX%
    call ci\x64-windows\countly.bat
    if errorlevel 1 goto :fail
    (echo 2)>%STATE_FILE%
    set LAST_STEP=2
)

REM --- Step 3: Build KDSingleApplication ---
if %LAST_STEP% LSS 3 (
    echo.
    echo [Step 3/11] Building KDSingleApplication...
    set PREFIX=%PREFIX%
    call ci\x64-windows\kdsingleapplication.bat
    if errorlevel 1 goto :fail
    (echo 3)>%STATE_FILE%
    set LAST_STEP=3
)

REM --- Step 4: Build ZXing ---
if %LAST_STEP% LSS 4 (
    echo.
    echo [Step 4/11] Building ZXing...
    set PREFIX=%PREFIX%
    call ci\x64-windows\zxing.bat
    if errorlevel 1 goto :fail
    (echo 4)>%STATE_FILE%
    set LAST_STEP=4
)

REM --- Step 5: Build hidapi ---
if %LAST_STEP% LSS 5 (
    echo.
    echo [Step 5/11] Building hidapi...
    set PREFIX=%PREFIX%
    call ci\x64-windows\hidapi.bat
    if errorlevel 1 goto :fail
    (echo 5)>%STATE_FILE%
    set LAST_STEP=5
)

REM --- Step 6: Build leveldb ---
if %LAST_STEP% LSS 6 (
    echo.
    echo [Step 6/11] Building leveldb...
    set PREFIX=%PREFIX%
    call ci\x64-windows\leveldb.bat
    if errorlevel 1 goto :fail
    (echo 6)>%STATE_FILE%
    set LAST_STEP=6
)

REM --- Step 7: Build LWK ---
if %LAST_STEP% LSS 7 (
    echo.
    echo [Step 7/11] Building LWK...
    set PREFIX=%PREFIX%
    call ci\x64-windows\lwk.bat
    if errorlevel 1 goto :fail
    (echo 7)>%STATE_FILE%
    set LAST_STEP=7
)

REM --- Step 8: Build GLSDK ---
if %LAST_STEP% LSS 8 (
    echo.
    echo [Step 8/11] Building GLSDK...
    set PREFIX=%PREFIX%
    call ci\x64-windows\glsdk.bat
    if errorlevel 1 goto :fail
    (echo 8)>%STATE_FILE%
    set LAST_STEP=8
)

REM --- Step 9: Configure CMake ---
if %LAST_STEP% LSS 9 (
    echo.
    echo [Step 9/11] Configuring with CMake...
    set CMAKE_PREFIX_PATH=%PREFIX%;%DEPENDS_PREFIX%
    if exist "%QT_ROOT%\bin\qt-cmake.bat" (call "%QT_ROOT%\bin\qt-cmake.bat" -S . -B bld -DCMAKE_PREFIX_PATH=%PREFIX%;%DEPENDS_PREFIX% -DCMAKE_BUILD_TYPE=RelWithDebInfo -DGREEN_ENV=Testing -DGREEN_BUILD_ID=-dev -DGREEN_LOG_FILE=dev -DENABLE_SENTRY=OFF -DCMAKE_POLICY_VERSION_MINIMUM=3.5) else (call "%QT_ROOT%\bin\qt-cmake.exe" -S . -B bld -DCMAKE_PREFIX_PATH=%PREFIX%;%DEPENDS_PREFIX% -DCMAKE_BUILD_TYPE=RelWithDebInfo -DGREEN_ENV=Testing -DGREEN_BUILD_ID=-dev -DGREEN_LOG_FILE=dev -DENABLE_SENTRY=OFF -DCMAKE_POLICY_VERSION_MINIMUM=3.5)
    if errorlevel 1 goto :fail
    (echo 9)>%STATE_FILE%
    set LAST_STEP=9
)

REM --- Step 10: Build ---
if %LAST_STEP% LSS 10 (
    echo.
    echo [Step 10/11] Building...
    cmake --build bld --config RelWithDebInfo
    if errorlevel 1 goto :fail
    (echo 10)>%STATE_FILE%
    set LAST_STEP=10
)

REM --- Step 11: Deploy Qt and copy DLLs ---
if %LAST_STEP% LSS 11 (
    echo.
    echo [Step 11/11] Deploying Qt and copying DLLs...
    call "%QT_ROOT%\bin\windeployqt.exe" --qmldir qml bld\RelWithDebInfo\blockstream.exe
    if errorlevel 1 goto :fail
    copy /Y "%DEPENDS_PREFIX%\bin\libgreen_gdk.dll" bld\RelWithDebInfo\
    copy /Y "%DEPENDS_PREFIX%\bin\libserialport-0.dll" bld\RelWithDebInfo\
    (echo 11)>%STATE_FILE%
)

REM Success
del %STATE_FILE% 2>nul
echo.
echo ==========================================
echo BUILD SUCCESSFUL
echo ==========================================
echo.
echo Executable and DLLs are in: bld\RelWithDebInfo\
echo Run: bld\RelWithDebInfo\blockstream.exe
echo.
exit /b 0

:fail
echo.
echo ==========================================
echo BUILD FAILED
echo ==========================================
echo.
echo To resume from this step, run the script again:
echo   doc\windows\build.bat
echo.
echo To start over, run:
echo   doc\windows\build.bat --restart
echo.
exit /b 1

