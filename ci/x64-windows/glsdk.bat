@echo off
setlocal enabledelayedexpansion

set PATH=%PATH%;C:\cargo\bin

set GLSDK_REPO=https://github.com/Blockstream/greenlight
set GLSDK_BRANCH=gl-sdk-v0.4.0
set GLSDK_COMMIT=c804a01e6f47e1201cfd107f9100704252443a44
set TARGET=x86_64-pc-windows-msvc

git clone --recurse-submodules --quiet --depth 1 --branch %GLSDK_BRANCH% %GLSDK_REPO% glsdk-src

cd glsdk-src
git rev-parse HEAD
git checkout %GLSDK_COMMIT% || exit /b 1

cargo build --target %TARGET% --release -p gl-sdk || exit /b 1

set RELEASE_DIR=target\%TARGET%\release

cmake -E make_directory %PREFIX%\lib
cmake -E make_directory %PREFIX%\bin

:: Static library, linked directly into the app.
copy %RELEASE_DIR%\glsdk.lib %PREFIX%\lib\

:: The windows.<ver>.lib umbrella import libs are bundled by the Rust windows-targets
:: crate (not the Windows SDK), so the MSVC linker can't find them when linking glsdk.lib
:: externally. Copy them next to glsdk.lib so they're on the link path.
for /r C:\cargo\registry\src %%f in (windows.*.lib) do copy /y "%%f" %PREFIX%\lib\

:: cdylib + its import lib, kept as a fallback if static linking is problematic.
copy %RELEASE_DIR%\glsdk.dll %PREFIX%\bin\
copy %RELEASE_DIR%\glsdk.dll.lib %PREFIX%\bin\

:: Print the native system libs needed to statically link glsdk.lib.
cargo rustc --release -p gl-sdk --target %TARGET% --crate-type staticlib -- --print native-static-libs

:: Same MAX_PATH limit on ImportLayer as in lwk.bat -- see the comment there.
cd \
rmdir /s /q C:\glsdk-src
rmdir /s /q C:\cargo\registry

endlocal
