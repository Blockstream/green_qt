#!/usr/bin/env bash
# Source from CI before_script when building macOS x86_64 on an Apple Silicon runner.
# Usage: source tools/ci/macos-x86_64-cross-env.sh
#
# Expects HOST/ARCH/PREFIX (and usually Qt on PATH) already set by the job.

if [[ "$(uname -m)" != "arm64" ]]; then
    echo "macos-x86_64-cross-env.sh expects an arm64 host (cross-build)."
    return 1 2>/dev/null || exit 1
fi

_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${_SCRIPT_DIR}/../.." && pwd)"
SDK="$(xcrun --sdk macosx --show-sdk-path)"
export CMAKE_TOOLCHAIN_FILE="${ROOT_DIR}/cmake/macos-x86_64-cross.cmake"
export CMAKE_OSX_ARCHITECTURES=x86_64
export CMAKE_OSX_DEPLOYMENT_TARGET="${MACOSX_DEPLOYMENT_TARGET:-12.0}"
export GDK_MACOS_TARGET_ARCH=x86_64

ARCH_FLAGS="-arch x86_64 -isysroot ${SDK} -mmacosx-version-min=${CMAKE_OSX_DEPLOYMENT_TARGET}"
export CC=clang
export CXX=clang++
export CFLAGS="${ARCH_FLAGS}"
export CXXFLAGS="${ARCH_FLAGS}"
export LDFLAGS="${ARCH_FLAGS}"

# Ensure Rust can cross-compile crates used by lwk / glsdk / GDK.
if command -v rustup >/dev/null 2>&1; then
    rustup target add x86_64-apple-darwin >/dev/null
    if rustup toolchain list 2>/dev/null | grep -q '^1.85.0-aarch64-apple-darwin'; then
        rustup target add x86_64-apple-darwin --toolchain 1.85.0-aarch64-apple-darwin >/dev/null
    fi
fi
