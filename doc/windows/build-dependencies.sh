#!/usr/bin/env bash
#
# Phase 1 of Windows build: Build GDK and libserialport on Linux (MinGW).
# Run this in WSL2, Docker, or native Linux. Then copy artifacts to Windows
# and run doc/windows/build.bat there.
#
# Prerequisites: See doc/windows/README.md (MinGW, Rust, gendef, protoc, etc.)
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$SCRIPT_DIR"
STATE_FILE=".build_state_windows_phase1"

# Default PREFIX - can be overridden. Use /depends for Docker CI compatibility.
# For WSL2 copying to C:\, use /mnt/c/depends/windows-x86_64
export PREFIX="${PREFIX:-$SCRIPT_DIR/depends/windows-x86_64}"

# Step definitions
STEP_PREREQS=1
STEP_ENV=2
STEP_GDK=3
STEP_LIBSERIALPORT=4
STEP_COPY=5
STEP_DONE=6

step_name() {
    case "$1" in
        $STEP_PREREQS) echo "prerequisites check" ;;
        $STEP_ENV) echo "environment setup" ;;
        $STEP_GDK) echo "GDK build" ;;
        $STEP_LIBSERIALPORT) echo "libserialport build" ;;
        $STEP_COPY) echo "copy artifacts" ;;
        $STEP_DONE) echo "complete" ;;
        *) echo "step $1" ;;
    esac
}

fail() {
    echo ""
    echo "=========================================="
    echo "PHASE 1 FAILED at $(step_name "$CURRENT_STEP")"
    echo "=========================================="
    echo ""
    echo "Error: $1"
    echo ""
    echo "To resume from this step, run the script again:"
    echo "  ./doc/windows/build-dependencies.sh"
    echo ""
    echo "To start over from the beginning, run:"
    echo "  ./doc/windows/build-dependencies.sh --restart"
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
    echo "Starting fresh Phase 1 build (--restart)."
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

    if ! command -v x86_64-w64-mingw32-g++-posix &>/dev/null && ! command -v x86_64-w64-mingw32-g++ &>/dev/null; then
        fail "MinGW not found. Run: sudo apt install g++-mingw-w64-x86-64 gcc-mingw-w64-x86-64 mingw-w64 mingw-w64-tools"
    fi

    if ! command -v rustc &>/dev/null; then
        fail "Rust not found. Install via: curl https://sh.rustup.rs -sSf | sh -s -- -y --default-toolchain 1.88.0 && rustup target add x86_64-pc-windows-gnu"
    fi

    if ! command -v gendef &>/dev/null; then
        fail "gendef not found. Run: sudo apt install mingw-w64-tools"
    fi

    if ! command -v protoc &>/dev/null; then
        fail "protoc not found. Run: sudo apt install protobuf-compiler"
    fi

    for cmd in cmake git; do
        if ! command -v "$cmd" &>/dev/null; then
            fail "Missing $cmd. Run: sudo apt install cmake git"
        fi
    done

    save_progress $STEP_PREREQS
fi

# --- Step 2: Environment ---
CURRENT_STEP=$STEP_ENV
if [[ "$LAST_STEP" -lt $STEP_ENV ]]; then
    echo ""
    echo "[Step 2/5] Setting up environment..."

    export HOST=windows
    export ARCH=x86_64
    export PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig"
    export CMAKE_INSTALL_PREFIX="$PREFIX"
    export CMAKE_TOOLCHAIN_FILE="$SCRIPT_DIR/cmake/mingw-w64-x86_64.cmake"

    mkdir -p "$PREFIX/bin" "$PREFIX/lib" "$PREFIX/include"

    [[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"

    echo "  PREFIX=$PREFIX"

    save_progress $STEP_ENV
fi

# --- Step 3: Build GDK ---
CURRENT_STEP=$STEP_GDK
if [[ "$LAST_STEP" -lt $STEP_GDK ]]; then
    echo ""
    echo "[Step 3/5] Building GDK for Windows..."

    export HOST=windows ARCH=x86_64
    export PREFIX="${PREFIX}"
    export PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig"
    export CMAKE_INSTALL_PREFIX="$PREFIX"
    export CMAKE_TOOLCHAIN_FILE="$SCRIPT_DIR/cmake/mingw-w64-x86_64.cmake"
    [[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"

    ./tools/buildgdk.sh || fail "buildgdk.sh failed"

    GDK_DLL="build/gdk/build-windows-mingw-w64/src/libgreen_gdk.dll"
    if [[ ! -f "$GDK_DLL" ]]; then
        fail "GDK DLL not found at $GDK_DLL"
    fi
    cp "$GDK_DLL" "$PREFIX/bin/"
    (cd "$PREFIX/bin" && gendef libgreen_gdk.dll) || fail "gendef libgreen_gdk.dll failed"

    save_progress $STEP_GDK
fi

# --- Step 4: Build libserialport ---
CURRENT_STEP=$STEP_LIBSERIALPORT
if [[ "$LAST_STEP" -lt $STEP_LIBSERIALPORT ]]; then
    echo ""
    echo "[Step 4/5] Building libserialport for Windows..."

    export HOST=windows ARCH=x86_64
    export PREFIX="${PREFIX}"
    export PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig"
    export CMAKE_INSTALL_PREFIX="$PREFIX"
    export CMAKE_TOOLCHAIN_FILE="$SCRIPT_DIR/cmake/mingw-w64-x86_64.cmake"

    ./tools/buildlibserialport.sh || fail "buildlibserialport.sh failed"

    LIBSERIALPORT_DLL="$PREFIX/bin/libserialport-0.dll"
    if [[ ! -f "$LIBSERIALPORT_DLL" ]]; then
        LIBSERIALPORT_DLL="$PREFIX/lib/libserialport-0.dll"
    fi
    if [[ -f "$LIBSERIALPORT_DLL" ]]; then
        cp "$LIBSERIALPORT_DLL" "$PREFIX/bin/" 2>/dev/null || true
        (cd "$PREFIX/bin" && gendef libserialport-0.dll) || fail "gendef libserialport-0.dll failed"
    else
        fail "libserialport DLL not found"
    fi

    save_progress $STEP_LIBSERIALPORT
fi

# --- Step 5: Copy to Windows (optional, for WSL2) ---
CURRENT_STEP=$STEP_COPY
if [[ "$LAST_STEP" -lt $STEP_COPY ]]; then
    echo ""
    echo "[Step 5/5] Phase 1 artifacts ready."

    if [[ -d /mnt/c ]]; then
        echo ""
        read -p "Copy artifacts to C:\\depends\\windows-x86_64? [y/N] " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            mkdir -p /mnt/c/depends
            rm -rf /mnt/c/depends/windows-x86_64
            cp -a "$PREFIX" /mnt/c/depends/windows-x86_64
            echo "  Copied to C:\\depends\\windows-x86_64"
        fi
        echo ""
    else
        echo "  (Skipping auto-copy: /mnt/c not found. Copy $PREFIX manually to Windows.)"
    fi

    save_progress $STEP_COPY
fi

# Success
save_progress $STEP_DONE
rm -f "$STATE_FILE" "$STATE_FILE.failed"

echo ""
echo "=========================================="
echo "PHASE 1 COMPLETE"
echo "=========================================="
echo ""
echo "Artifacts are in: $PREFIX"
echo ""
echo "Next steps:"
echo "  1. Copy the entire $PREFIX directory to your Windows machine"
echo "     (e.g. to C:\\depends\\windows-x86_64)"
echo "  2. On Windows, open 'x64 Native Tools Command Prompt for VS 2022'"
echo "  3. cd to the repo and run: doc\\windows\\build.bat"
echo ""

