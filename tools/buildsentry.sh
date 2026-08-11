#!/bin/bash
set -exo pipefail

# Linux Crashpad stacktraces require libunwind-ptrace (Debian/Ubuntu: libunwind-dev,
# Fedora/RHEL: libunwind-devel). See doc/linux/README.md and ci/linux-x86_64/setup.sh.
case "${HOST:-}" in
    windows|macos) ;;
    *)
        if [[ "$(uname -s)" == "Linux" ]] && ! pkg-config --exists libunwind-ptrace; then
            echo "Missing libunwind-ptrace. Install libunwind-dev (Debian/Ubuntu) or libunwind-devel (Fedora/RHEL)." >&2
            exit 1
        fi
        ;;
esac

SENTRY_REPO=https://github.com/getsentry/sentry-native
SENTRY_TAG=0.16.2
SENTRY_COMMIT=724479b549a299ea8363994306b36a00c754fcba

PATCHES=$(cd "$(dirname "$0")/patches" && pwd)

mkdir -p build && cd build && rm -rf sentry-native-src

git clone --recurse-submodules --quiet --branch $SENTRY_TAG --single-branch $SENTRY_REPO sentry-native-src

(cd sentry-native-src && git rev-parse HEAD && git checkout $SENTRY_COMMIT && git submodule update --init --recursive)

# Keep secrets out of the minidumps we upload; see the patch headers.
for patch in "$PATCHES"/*.patch; do
    git -C sentry-native-src/external/crashpad apply --ignore-whitespace "$patch"
done

qt-cmake -S sentry-native-src -B sentry-native-bld \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DCMAKE_OSX_DEPLOYMENT_TARGET=12.0 \
    -DSENTRY_BACKEND=crashpad \
    -DCRASHPAD_ENABLE_STACKTRACE=ON \
    -DSENTRY_INTEGRATION_QT=OFF \
    -DSENTRY_BUILD_SHARED_LIBS=OFF \
    -DSENTRY_BUILD_EXAMPLES=OFF \
    -DSENTRY_BUILD_TESTS=OFF

cmake --build sentry-native-bld --config RelWithDebInfo

cmake --install sentry-native-bld --strip --prefix $PREFIX

# CRASHPAD_ENABLE_STACKTRACE makes crashpad install its vendored LLVM libunwind
# (macOS only). The handler needs just the remote unwinding API (unw_*) to walk
# the crashed task; the level-1 EH ABI in the same archive (_Unwind_Resume,
# _Unwind_RaiseException) gets pulled onto the app's link line by
# crashpad_snapshot and replaces the system unwinder, which aborts on every C++
# throw. Drop those members so the app keeps unwinding via libunwind.dylib.
UNWIND_LIB="$PREFIX/lib/libunwind.a"
if [ -f "$UNWIND_LIB" ]; then
    EH_MEMBERS=$(ar t "$UNWIND_LIB" | grep -E '^(UnwindLevel1(-gcc-ext)?\.c|Unwind-sjlj\.c|Unwind-EHABI\.cpp|Unwind-seh\.cpp)\.o$' || true)
    if [ -n "$EH_MEMBERS" ]; then
        ar d "$UNWIND_LIB" $EH_MEMBERS
        ranlib "$UNWIND_LIB"
    fi
fi
