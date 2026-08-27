setlocal enabledelayedexpansion

set VERSION=1.2.1
set FILENAME=kdsingleapplication-%VERSION%
set ARCHIVE=%FILENAME%.tar.gz
set DIRNAME=%FILENAME%
set HASH=e3254ce9dc5ecf6d61ef83264bc61d486a307f0e3c9ed1bb2176f068cdbcbe09

curl -s -L -o %ARCHIVE% https://github.com/KDAB/KDSingleApplication/releases/download/v%VERSION%/%ARCHIVE%

certutil -hashfile %ARCHIVE% SHA256 | findstr /i /c:"%HASH%" >nul
if errorlevel 1 (
    echo Checksum verification failed for %ARCHIVE%
    exit /b 1
)

7z x %ARCHIVE% -so | 7z x -si -ttar

call \qt\6.11.2\msvc2022_64\bin\qt-cmake -S %FILENAME% -B kdsingleapplication-bld ^
    -DBUILD_SHARED_LIBS=OFF ^
    -DKDSingleApplication_STATIC=true ^
    -DKDSingleApplication_TESTS=false ^
    -DKDSingleApplication_EXAMPLES=false ^
    -DKDSingleApplication_DOCS=false

cmake --build kdsingleapplication-bld --config Release

cmake --install kdsingleapplication-bld --strip --prefix %PREFIX% || exit /b 1

:: Keep the layer small -- nothing after this step needs the source or build tree.
del /q %ARCHIVE%
rmdir /s /q %FILENAME%
rmdir /s /q kdsingleapplication-bld

endlocal
