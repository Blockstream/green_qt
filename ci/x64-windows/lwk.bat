@echo off
setlocal enabledelayedexpansion

set PATH=%PATH%;C:\cargo\bin

set LWK_REPO=https://github.com/Blockstream/lwk
set LWK_COMMIT=f3b10f522c0aa334b637fa9bc9a50f8beed860f7
set TARGET=x86_64-pc-windows-msvc

git clone --recurse-submodules --quiet %LWK_REPO% lwk-src

cd lwk-src
git rev-parse HEAD
git checkout %LWK_COMMIT%
git submodule update --init --recursive

cargo build --target %TARGET% --release -p lwk_bindings || exit /b 1

set RELEASE_DIR=target\%TARGET%\release

cmake -E make_directory %PREFIX%\lib
cmake -E make_directory %PREFIX%\bin

:: Static library, linked directly into the app.
copy %RELEASE_DIR%\lwk.lib %PREFIX%\lib\

:: The windows.<ver>.lib umbrella import libs are bundled by the Rust windows-targets
:: crate (not the Windows SDK), so the MSVC linker can't find them when linking lwk.lib
:: externally. Copy them next to lwk.lib so they're on the link path.
for /r C:\cargo\registry\src %%f in (windows.*.lib) do copy /y "%%f" %PREFIX%\lib\

:: cdylib + its import lib, kept as a fallback if static linking is problematic.
copy %RELEASE_DIR%\lwk.dll %PREFIX%\bin\
copy %RELEASE_DIR%\lwk.dll.lib %PREFIX%\bin\

:: Print the native system libs needed to statically link lwk.lib.
cargo rustc --release -p lwk_bindings --target %TARGET% --crate-type staticlib -- --print native-static-libs

:: Docker's Windows graphdriver re-creates every path in this layer under
:: C:\ProgramData\Docker\windowsfilter\<64-hex-id>\Files\ -- about 106 characters of
:: prefix -- and ImportLayer is still bound by MAX_PATH (260). The cargo target tree and
:: the extracted crate sources are by far the deepest paths here. Nothing after this step
:: needs any of it, so the whole lot goes before the layer is committed -- including the
:: download cache, so glsdk.bat re-downloads its crates rather than shipping them here.
cd \
rmdir /s /q C:\lwk-src
rmdir /s /q C:\cargo\registry

endlocal
