#!/usr/bin/env bash
#
# Automated build script for Blockstream Green on Linux.
#
# Prerequisites (install manually if missing):
#   - Ubuntu 22.04+ or compatible distro
#   - System packages (see doc/linux/README.md)
#   - Rust: curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
#   - Qt 6.11.1: from https://www.qt.io/download-qt-installer
#

set -e

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"
STATE_FILE=".build_state_linux"

# Step definitions
STEP_PREREQS=1
STEP_ENV=2
STEP_DEPS=3
STEP_CONFIGURE=4
STEP_BUILD=5
STEP_DONE=6

step_name() {
    case "$1" in
        $STEP_PREREQS) echo "prerequisites check" ;;
        $STEP_ENV) echo "environment setup" ;;
        $STEP_DEPS) echo "third-party dependencies" ;;
        $STEP_CONFIGURE) echo "CMake configure" ;;
        $STEP_BUILD) echo "build" ;;
        $STEP_DONE) echo "complete" ;;
        *) echo "step $1" ;;
    esac
}

fail() {
    echo ""
    echo "=========================================="
    echo "BUILD FAILED at $(step_name "$CURRENT_STEP")"
    echo "=========================================="
    echo ""
    echo "Error: $1"
    echo ""
    echo "To resume from this step, run the script again:"
    echo "  ./doc/linux/build.sh"
    echo ""
    echo "To start over from the beginning, run:"
    echo "  ./doc/linux/build.sh --restart"
    echo ""
    echo "$CURRENT_STEP" > "$STATE_FILE.failed"
    exit 1
}

save_progress() {
    echo "$1" > "$STATE_FILE"
}

read_progress() {
    if [[ -f "$STATE_FILE" ]]; then
        cat "$STATE_FILE"
    else
        echo "0"
    fi
}

# Ensure Qt is available when resuming
ensure_qt() {
    if [[ -z "${QT_ROOT:-}" || ! -f "$QT_ROOT/bin/qmake" ]]; then
        for q in "$HOME/Qt/6.11.1/gcc_64"; do
            if [[ -d "$q" && -f "$q/bin/qmake" ]]; then
                export QT_ROOT="$q"
                return
            fi
        done
        fail "Qt 6.11.1 not found. Set QT_ROOT or install Qt from https://www.qt.io/download-qt-installer"
    fi
}

# Parse arguments
RESTART=false
for arg in "$@"; do
    if [[ "$arg" == "--restart" ]]; then
        RESTART=true
    fi
done

# Resume or restart logic
if [[ "$RESTART" == true ]]; then
    rm -f "$STATE_FILE" "$STATE_FILE.failed"
    LAST_STEP=0
    echo "Starting fresh build (--restart)."
elif [[ -f "$STATE_FILE.failed" ]]; then
    FAILED_AT=$(cat "$STATE_FILE.failed")
    LAST_STEP=$(read_progress)
    echo "Previous run failed at $(step_name "$FAILED_AT")."
    echo "Resuming from $(step_name "$((LAST_STEP + 1))")..."
    rm -f "$STATE_FILE.failed"
else
    LAST_STEP=$(read_progress)
    if [[ "$LAST_STEP" -gt 0 ]]; then
        echo "Resuming from $(step_name "$((LAST_STEP + 1))") (last completed: $(step_name "$LAST_STEP"))."
    fi
fi

# --- Step 1: Prerequisites ---
CURRENT_STEP=$STEP_PREREQS
if [[ "$LAST_STEP" -lt $STEP_PREREQS ]]; then
    echo ""
    echo "[Step 1/5] Checking prerequisites..."

    for cmd in cmake ninja git pkg-config protoc; do
        if ! command -v "$cmd" &>/dev/null; then
            fail "Missing $cmd. Install build dependencies (see doc/linux/README.md): sudo apt install build-essential cmake ninja-build git pkg-config protobuf-compiler ..."
        fi
    done

    if ! command -v rustc &>/dev/null; then
        fail "Rust not found. Install via: curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
    fi

    ensure_qt
    echo "  Qt found: $QT_ROOT"

    save_progress $STEP_PREREQS
fi

# --- Step 2: Environment ---
CURRENT_STEP=$STEP_ENV
if [[ "$LAST_STEP" -lt $STEP_ENV ]]; then
    echo ""
    echo "[Step 2/5] Setting up environment..."
    ensure_qt

    export HOST=linux
    export ARCH=x86_64
    export PREFIX="$PWD/depends/linux-x86_64"
    export PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig"
    export CMAKE_INSTALL_PREFIX="$PREFIX"
    export PATH="$QT_ROOT/bin:$PREFIX/bin:$PATH"
    export CMAKE_PREFIX_PATH="$QT_ROOT:$PREFIX"

    echo "  PREFIX=$PREFIX"

    save_progress $STEP_ENV
fi

# --- Step 3: Build dependencies ---
CURRENT_STEP=$STEP_DEPS
if [[ "$LAST_STEP" -lt $STEP_DEPS ]]; then
    echo ""
    echo "[Step 3/5] Building third-party dependencies (this may take a while)..."
    ensure_qt

    export HOST=linux
    export ARCH=x86_64
    export PREFIX="$PWD/depends/linux-x86_64"
    export PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig"
    export CMAKE_INSTALL_PREFIX="$PREFIX"
    export PATH="$QT_ROOT/bin:$PREFIX/bin:$PATH"
    export CMAKE_PREFIX_PATH="$QT_ROOT:$PREFIX"

    unset LD_LIBRARY_PATH

    [[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"

    rm -rf "$PREFIX"

    rm -rf build/zxing-cpp-src build/zxing-cpp-bld
    rm -rf build/libserialport-src build/libserialport-bld

    ./tools/buildgdk.sh --static || fail "buildgdk.sh failed"
    ./tools/buildbreakpad.sh || fail "buildbreakpad.sh failed"
    ./tools/buildcrashpad.sh || fail "buildcrashpad.sh failed"
    ./tools/buildgpgme.sh || fail "buildgpgme.sh failed"
    ./tools/buildlibusb.sh || fail "buildlibusb.sh failed"
    ./tools/buildhidapi.sh || fail "buildhidapi.sh failed"
    ./tools/buildcountly.sh || fail "buildcountly.sh failed"
    ./tools/buildzxing.sh || fail "buildzxing.sh failed"
    ./tools/buildlibserialport.sh --disable-shared || fail "buildlibserialport.sh failed"
    ./tools/buildkdsingleapplication.sh || fail "buildkdsingleapplication.sh failed"
    ./tools/buildlwk.sh || fail "buildlwk.sh failed"
    ./tools/buildglsdk.sh || fail "buildglsdk.sh failed"
    ./tools/buildleveldb.sh || fail "buildleveldb.sh failed"

    save_progress $STEP_DEPS
fi

# --- Step 4: Configure ---
CURRENT_STEP=$STEP_CONFIGURE
if [[ "$LAST_STEP" -lt $STEP_CONFIGURE ]]; then
    echo ""
    echo "[Step 4/5] Configuring with CMake..."
    ensure_qt

    export PREFIX="$PWD/depends/linux-x86_64"
    export PATH="$QT_ROOT/bin:$PREFIX/bin:$PATH"
    export CMAKE_PREFIX_PATH="$QT_ROOT:$PREFIX"

    CANDIDATES=(
        "$PREFIX/lib64/x86_64-linux-gnu/gdk/cmake"
        "$PREFIX/lib/x86_64-linux-gnu/gdk/cmake"
        "$PREFIX/lib64/cmake/gdk"
        "$PREFIX/lib/cmake/gdk"
    )

    GDK_CMAKE_DIR=""
    for d in "${CANDIDATES[@]}"; do
        if [[ -f "$d/gdk-config.cmake" ]]; then
            GDK_CMAKE_DIR="$d"
            break
        fi
    done

    if [[ -z "$GDK_CMAKE_DIR" ]]; then
        fail "gdk CMake config not found under $PREFIX (tried: ${CANDIDATES[*]}). Run dependency build and/or adjust search list."
    fi

    qt-cmake --preset dev -Dgdk_DIR="$GDK_CMAKE_DIR" || fail "CMake configure failed"

    save_progress $STEP_CONFIGURE
fi

# --- Step 5: Build ---
CURRENT_STEP=$STEP_BUILD
if [[ "$LAST_STEP" -lt $STEP_BUILD ]]; then
    echo ""
    echo "[Step 5/5] Building..."

    NPROC=$(nproc 2>/dev/null || echo 4)
    cmake --build build --parallel "$NPROC" || fail "Build failed"

    save_progress $STEP_BUILD
fi

# Success
# Keep dependency step as last completed so subsequent runs only configure+build
save_progress $STEP_DEPS
rm -f "$STATE_FILE.failed"

echo ""
echo "=========================================="
echo "BUILD SUCCESSFUL"
echo "=========================================="
echo ""
echo "Dependencies are cached under: $PWD/depends/linux-x86_64"
echo ""
echo "Run the app with:"
echo "  export LD_LIBRARY_PATH=\"\$QT_ROOT/lib:\$LD_LIBRARY_PATH\""
echo "  ./build/blockstream"
echo ""
