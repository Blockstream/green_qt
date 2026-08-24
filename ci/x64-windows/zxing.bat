setlocal enabledelayedexpansion

set ZXING_REPO=https://github.com/Blockstream/zxing-cpp
set ZXING_COMMIT=4103a03c62e350913e994920157d916b4cc9632a

git clone %ZXING_REPO% zxing-cpp-src

cd zxing-cpp-src
git rev-parse HEAD
git checkout %ZXING_COMMIT%
git submodule update --init --recursive
cd ..

cmake -S zxing-cpp-src -B zxing-cpp-bld ^
  -DCMAKE_BUILD_TYPE=Release ^
  -DCMAKE_OSX_DEPLOYMENT_TARGET=12.0 ^
  -DBUILD_SHARED_LIBS=OFF ^
  -DZXING_C_API=OFF ^
  -DZXING_EXAMPLES=OFF ^
  -DZXING_DEPENDENCIES=LOCAL ^
  -DZXING_USE_BUNDLED_ZINT=ON

cmake --build zxing-cpp-bld --config Release

cmake --install zxing-cpp-bld --strip --prefix %PREFIX% || exit /b 1

:: Keep the layer small -- nothing after this step needs the source or build tree.
rmdir /s /q zxing-cpp-src
rmdir /s /q zxing-cpp-bld

endlocal
