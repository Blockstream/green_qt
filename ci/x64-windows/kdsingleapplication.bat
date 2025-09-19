setlocal enabledelayedexpansion

set VERSION=1.1.0
set FILENAME=kdsingleapplication-%VERSION%
set ARCHIVE=%FILENAME%.tar.gz
set DIRNAME=%FILENAME%

curl -s -L -o %ARCHIVE% https://github.com/KDAB/KDSingleApplication/releases/download/v%VERSION%/%ARCHIVE%

7z x %ARCHIVE% -so | 7z x -si -ttar

call \qt\6.8.3\msvc2022_64\bin\qt-cmake -S %FILENAME% -B kdsingleapplication-bld ^
    -DBUILD_SHARED_LIBS=OFF ^
    -DKDSingleApplication_QT6=true ^
    -DKDSingleApplication_STATIC=true ^
    -DKDSingleApplication_TESTS=false ^
    -DKDSingleApplication_EXAMPLES=false ^
    -DKDSingleApplication_DOCS=false

cmake --build kdsingleapplication-bld --config Release

cmake --install kdsingleapplication-bld --strip --prefix %PREFIX%

endlocal
