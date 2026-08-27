#!/usr/bin/env bash
#
# Automated build script for Blockstream app on macOS.
#
# Prerequisites (install manually if missing):
#   - Xcode command line tools: xcode-select --install
#   - Homebrew: https://brew.sh
#   - Bash 4+: brew install bash
#   - Build tools: brew install cmake ninja python git pkg-config protobuf
#   - Qt 6.11.2: from https://www.qt.io/download-qt-installer
#

set -e

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"
STATE_FILE=".build_state_macos"

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
    echo "  ./doc/macos/build.sh"
    echo ""
    echo "To start over from the beginning, run:"
    echo "  ./doc/macos/build.sh --restart"
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

    if ! xcode-select -p &>/dev/null; then
        fail "Xcode command line tools not found. Run: xcode-select --install"
    fi

    if ! command -v brew &>/dev/null; then
        fail "Homebrew not found. Install from https://brew.sh"
    fi

    BASH_VERSION=$(bash -c 'echo ${BASH_VERSINFO[0]}' 2>/dev/null || echo "0")
    if [[ "$BASH_VERSION" -lt 4 ]]; then
        fail "Bash 4+ required. macOS ships with Bash 3.2. Run: brew install bash"
    fi

    for cmd in cmake ninja python3 git pkg-config protoc; do
        if ! command -v "$cmd" &>/dev/null; then
            fail "Missing $cmd. Run: brew install cmake ninja python git pkg-config protobuf"
        fi
    done

    # Qt check - user must set QT_ROOT
    if [[ -z "$QT_ROOT" ]]; then
        # Try common locations
        for q in "$HOME/Qt/6.11.2/macos"; do
            if [[ -d "$q" && -f "$q/bin/qmake" ]]; then
                export QT_ROOT="$q"
                break
            fi
        done
    fi
    if [[ -z "$QT_ROOT" || ! -f "$QT_ROOT/bin/qmake" ]]; then
        fail "Qt 6.11 not found. Install Qt from https://www.qt.io/download-qt-installer and set QT_ROOT, e.g.: export QT_ROOT=\$HOME/Qt/6.11.2/macos"
    fi
    echo "  Qt found: $QT_ROOT"

    save_progress $STEP_PREREQS
fi

# Ensure QT_ROOT is available when resuming (set in step 1, but we may have started fresh)
ensure_qt() {
    if [[ -z "${QT_ROOT:-}" || ! -f "$QT_ROOT/bin/qmake" ]]; then
        for q in "$HOME/Qt/6.11.2/macos"; do
            if [[ -d "$q" && -f "$q/bin/qmake" ]]; then
                export QT_ROOT="$q"
                return
            fi
        done
        fail "Qt 6.11 not found. Set QT_ROOT or install Qt from https://www.qt.io/download-qt-installer"
    fi
}

# --- Step 2: Environment ---
CURRENT_STEP=$STEP_ENV
if [[ "$LAST_STEP" -lt $STEP_ENV ]]; then
    echo ""
    echo "[Step 2/5] Setting up environment..."
    ensure_qt

    ARCH=$(uname -m)
    if [[ "$ARCH" == "arm64" ]]; then
        export HOST=macos
        export ARCH=arm64
        export PREFIX="${PREFIX-$HOME/depends/macos-arm64}"
        export gdk_ROOT="$PREFIX/lib/arm64-apple-darwin/gdk"
    else
        export HOST=macos
        export ARCH=x86_64
        export PREFIX="${PREFIX-$HOME/depends/macos-x86_64}"
        export gdk_ROOT="$PREFIX/lib/x86_64-apple-darwin/gdk"
    fi

    export PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig"
    export CMAKE_INSTALL_PREFIX="$PREFIX"
    export CMAKE_POLICY_VERSION_MINIMUM=3.5
    export PATH="$QT_ROOT/bin:$PATH"
    export CMAKE_PREFIX_PATH="$QT_ROOT${CMAKE_PREFIX_PATH:+:$CMAKE_PREFIX_PATH}"

    echo "  PREFIX=$PREFIX"
    echo "  ARCH=$ARCH"

    save_progress $STEP_ENV
fi

# --- Step 3: Build dependencies ---
CURRENT_STEP=$STEP_DEPS
if [[ "$LAST_STEP" -lt $STEP_DEPS ]]; then
    echo ""
    echo "[Step 3/5] Building third-party dependencies (this may take a while)..."
    ensure_qt

    # Re-export in case we resumed
    ARCH=$(uname -m)
    if [[ "$ARCH" == "arm64" ]]; then
        export HOST=macos ARCH=arm64
        export PREFIX="${PREFIX-$HOME/depends/macos-arm64}"
        export gdk_ROOT="$PREFIX/lib/arm64-apple-darwin/gdk"
    else
        export HOST=macos ARCH=x86_64
        export PREFIX="${PREFIX-$HOME/depends/macos-x86_64}"
        export gdk_ROOT="$PREFIX/lib/x86_64-apple-darwin/gdk"
    fi
    export PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig"
    export CMAKE_INSTALL_PREFIX="$PREFIX"
    export CMAKE_POLICY_VERSION_MINIMUM=3.5
    export PATH="$QT_ROOT/bin:$PATH"
    export CMAKE_PREFIX_PATH="$QT_ROOT:$PREFIX:$gdk_ROOT"

    rm -rf "$PREFIX"

    rm -rf build/zxing-cpp-src build/zxing-cpp-bld
    rm -rf build/libserialport-src build/libserialport-bld

    ./tools/buildgdk.sh --static || fail "buildgdk.sh failed"
    ./tools/buildsentry.sh || fail "buildsentry.sh failed"
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

    ARCH=$(uname -m)
    if [[ "$ARCH" == "arm64" ]]; then
        export PREFIX="${PREFIX-$HOME/depends/macos-arm64}"
        export gdk_ROOT="$PREFIX/lib/arm64-apple-darwin/gdk"
    else
        export PREFIX="${PREFIX-$HOME/depends/macos-x86_64}"
        export gdk_ROOT="$PREFIX/lib/x86_64-apple-darwin/gdk"
    fi
    export PATH="$QT_ROOT/bin:$PATH"
    export CMAKE_PREFIX_PATH="$QT_ROOT:$PREFIX:$gdk_ROOT"

    qt-cmake --preset dev || fail "CMake configure failed"

    save_progress $STEP_CONFIGURE
fi

# --- Step 5: Build ---
CURRENT_STEP=$STEP_BUILD
if [[ "$LAST_STEP" -lt $STEP_BUILD ]]; then
    echo ""
    echo "[Step 5/5] Building..."

    NPROC=$(sysctl -n hw.ncpu 2>/dev/null || echo 4)
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
echo "Dependencies are cached under: $PREFIX"
echo ""
echo "Run the app with:"
echo "  open build/Blockstream.app"
echo ""
