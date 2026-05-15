#!/bin/bash
set -eo pipefail

REPO=https://github.com/Blockstream/greenlight
BRANCH=gl-sdk-v0.4.0

PROJECT_ROOT=$(pwd)
BUILD_DIR="${BUILD_DIR:-build/glsdk-src}"
GENERATE_BINDINGS=false

HELP_MSG="Usage: $0 [OPTIONS]
Options:
  --build-dir=DIR     Specify the build directory (default: build/glsdk-src)
  --bindings          Generate C++ bindings using uniffi-bindgen-cpp
  --clean             Clean build artifacts before building
  --verbose           Enable verbose output (set -x)
  --help              Show this help message and exit"

if [ -z "$PREFIX" ]; then
    echo "Error: PREFIX environment variable is not set. Please set PREFIX to the desired installation directory." >&2
    exit 1
fi

# Parse command-line arguments
for arg in "$@"; do
    if [[ "$arg" == "--build-dir="* ]]; then
        BUILD_DIR="${arg#*=}"
    elif [[ "$arg" == "--bindings" ]]; then
        GENERATE_BINDINGS=true
    elif [[ "$arg" == "--verbose" ]]; then
        set -x
    elif [[ "$arg" == "--clean" ]]; then
        echo "Cleaning build artifacts..."
        rm -rf "$BUILD_DIR"
    elif [[ "$arg" == "--help" ]]; then
        echo "$HELP_MSG"
        exit 0
    else
        echo "Unknown option: $arg" >&2
        echo "$HELP_MSG" >&2
        exit 1
    fi
done


# Build and install GLSDK
if [ -d "$BUILD_DIR" ]; then
    echo "Build directory '$BUILD_DIR' already exists. Use --clean to build from a clean state."
else
    git clone --quiet --depth 1 --branch "$BRANCH" "$REPO" "$BUILD_DIR"
fi

cd "$BUILD_DIR"

echo "Building gl-sdk with BUILD_DIR='$BUILD_DIR', HOST='$HOST', PREFIX='$PREFIX'..."
if [ "$HOST" = "windows" ]; then
    cargo build --target x86_64-pc-windows-gnu --release -p gl-sdk
    cd target/x86_64-pc-windows-gnu/release
    gendef glsdk.dll

    install -d $PREFIX/bin
    install glsdk.dll $PREFIX/bin
    install glsdk.def $PREFIX/bin

    # Install MinGW runtime DLLs required by glsdk.dll
    install "$(x86_64-w64-mingw32-g++ -print-file-name=libstdc++-6.dll)" $PREFIX/bin
    install "$(x86_64-w64-mingw32-g++ -print-libgcc-file-name | xargs dirname)/libgcc_s_seh-1.dll" $PREFIX/bin
    install "$(x86_64-w64-mingw32-g++ -print-file-name=libwinpthread-1.dll)" $PREFIX/bin

    LIBPATH="target/x86_64-pc-windows-gnu/release/glsdk.dll"
elif [ "$HOST" = "macos" ]; then
    cargo build --release -p gl-sdk
    install -d $PREFIX/lib
    install target/release/libglsdk.dylib $PREFIX/lib
    install_name_tool -id @rpath/libglsdk.dylib $PREFIX/lib/libglsdk.dylib
    LIBPATH="target/release/libglsdk.dylib"
elif [ "$HOST" = "linux" ]; then
    cargo build --release -p gl-sdk
    install -d $PREFIX/lib
    install ./target/release/libglsdk.so $PREFIX/lib
    LIBPATH="target/release/libglsdk.so"
else
    echo "Error: Unsupported HOST value '$HOST'. Supported: windows, macos, linux." >&2
    exit 1
fi

# Generate C++ bindings if --bindings flag is present.
if [ "$GENERATE_BINDINGS" = true ]; then
    echo "Generating C++ bindings with uniffi-bindgen-cpp..."

    OUTDIR="$PROJECT_ROOT/src/glsdk"
	cargo install uniffi-bindgen-cpp --git https://github.com/NordSecurity/uniffi-bindgen-cpp --tag v0.8.1+v0.29.4
	uniffi-bindgen-cpp --library "$LIBPATH" --out-dir "$OUTDIR"

    # Patch generated C++ identifiers that conflict with reserved keyword `register`.
    perl -pi -e 's/std::shared_ptr<Node> register\(/std::shared_ptr<Node> register_node\(/g; s/std::shared_ptr<Credentials> register\(/std::shared_ptr<Credentials> register_node\(/g' "$OUTDIR/glsdk.hpp"
    perl -pi -e 's/NodeBuilder::register\(/NodeBuilder::register_node\(/g; s/Scheduler::register\(/Scheduler::register_node\(/g' "$OUTDIR/glsdk.cpp"
else
    echo "Skipping C++ bindings generation. Pass --bindings to generate bindings with uniffi-bindgen-cpp."
fi
