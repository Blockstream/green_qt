setlocal enabledelayedexpansion

set ZXING_REPO=https://github.com/Blockstream/zxing-cpp
set ZXING_COMMIT=1a5337abde0be7aef84907f5f1ca3ed09d34f713

git clone %ZXING_REPO% zxing-cpp-src

cd zxing-cpp-src
git rev-parse HEAD
git checkout %ZXING_COMMIT%
cd ..

cmake -S zxing-cpp-src -B zxing-cpp-bld ^
  -DCMAKE_BUILD_TYPE=Release ^
  -DCMAKE_OSX_DEPLOYMENT_TARGET=12.0 ^
  -DBUILD_SHARED_LIBS=OFF ^
  -DZXING_C_API=OFF ^
  -DZXING_EXAMPLES=OFF ^
  -DZXING_DEPENDENCIES=LOCAL ^
  -DZXING_USE_BUNDLED_ZINT=OFF

cmake --build zxing-cpp-bld --config Release

cmake --install zxing-cpp-bld --strip --prefix %PREFIX%

endlocal
