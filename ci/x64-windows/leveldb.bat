@echo off
setlocal enabledelayedexpansion

set LEVELDB_REPO=https://github.com/google/leveldb.git
set LEVELDB_COMMIT=99b3c03b3284f5886f9ef9a4ef703d57373e61be

git clone --quiet --no-checkout %LEVELDB_REPO% leveldb-src

cd leveldb-src
git rev-parse HEAD
git checkout %LEVELDB_COMMIT%
cd ..

cmake -S leveldb-src -B leveldb-bld ^
    -DBUILD_SHARED_LIBS=OFF ^
    -DLEVELDB_BUILD_TESTS=OFF ^
    -DLEVELDB_BUILD_BENCHMARKS=OFF

cmake --build leveldb-bld --config Release

cmake --install leveldb-bld --strip --prefix %PREFIX% || exit /b 1

:: Keep the layer small -- nothing after this step needs the source or build tree.
rmdir /s /q leveldb-src
rmdir /s /q leveldb-bld

endlocal
