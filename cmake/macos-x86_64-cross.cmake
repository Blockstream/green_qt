# Cross-compile for Intel macOS (x86_64) on Apple Silicon.
#
# Usage:
#   cmake -DCMAKE_TOOLCHAIN_FILE=$PWD/cmake/macos-x86_64-cross.cmake ...
#
set(CMAKE_SYSTEM_NAME Darwin)
set(CMAKE_OSX_ARCHITECTURES x86_64)
set(CMAKE_OSX_DEPLOYMENT_TARGET "12.0" CACHE STRING "Minimum macOS deployment target")

set(CMAKE_C_FLAGS_INIT "-arch x86_64")
set(CMAKE_CXX_FLAGS_INIT "-arch x86_64")
