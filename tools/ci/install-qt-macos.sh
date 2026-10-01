#!/bin/bash
# Usage: install-qt-macos.sh <qt-version> [webengine-id]
# Installs Qt into $QT_INSTALL_ROOT/<qt-version> (default ~/Qt) unless that version is already there.
# webengine-id is the qtwebengine component segment, e.g. 6120.61400; defaults to the Qt version digits.
set -eo pipefail

QT_VERSION=$1
if [ -z "$QT_VERSION" ]; then
    echo "usage: $0 <qt-version> [webengine-id]" >&2
    exit 1
fi
QT_ID=${QT_VERSION//./}
WEBENGINE_ID=${2:-$QT_ID}
ROOT="${QT_INSTALL_ROOT:-$HOME/Qt}/$QT_VERSION"
PREFIX="$ROOT/$QT_VERSION/macos"

installed() {
    [ "$("$PREFIX/bin/qmake" -query QT_VERSION 2>/dev/null)" = "$QT_VERSION" ] &&
        [ -d "$PREFIX/lib/QtWebEngineCore.framework" ]
}

if installed; then
    echo "Qt $QT_VERSION already installed at $PREFIX"
    exit 0
fi

if [ -z "$QT_INSTALLER_JWT_TOKEN" ]; then
    echo "QT_INSTALLER_JWT_TOKEN is not set" >&2
    exit 1
fi

mkdir -p "$(dirname "$ROOT")"
LOCK="$ROOT.lock"
LOCKED=
for _ in $(seq 360); do
    mkdir "$LOCK" 2>/dev/null && LOCKED=1 && break
    echo "Waiting for $LOCK"
    sleep 10
done
[ -n "$LOCKED" ] || { echo "Timed out waiting for $LOCK" >&2; exit 1; }

WORK=$(mktemp -d)
MOUNT="$WORK/mnt"
cleanup() {
    hdiutil detach "$MOUNT" -quiet 2>/dev/null || true
    rm -rf "$WORK" "$LOCK"
}
trap cleanup EXIT

# Another job may have finished the install while this one waited for the lock.
if installed; then
    echo "Qt $QT_VERSION already installed at $PREFIX"
    exit 0
fi

rm -rf "$ROOT"

curl -sSfL -o "$WORK/installer.dmg" https://download.qt.io/official_releases/online_installers/qt-online-installer-macOS-universal.dmg
mkdir "$MOUNT"
hdiutil attach "$WORK/installer.dmg" -nobrowse -readonly -mountpoint "$MOUNT" -quiet
INSTALLER=$(echo "$MOUNT"/*.app/Contents/MacOS/qt-online-installer-*)

"$INSTALLER" \
    --root "$ROOT" \
    --accept-licenses --default-answer --confirm-command --accept-obligations \
    install \
        qt.qt6.$QT_ID.clang_64 \
        qt.qt6.$QT_ID.addons.qt5compat \
        qt.qt6.$QT_ID.addons.qtconnectivity \
        qt.qt6.$QT_ID.addons.qtmultimedia \
        qt.qt6.$QT_ID.addons.qtserialport \
        qt.qt6.$QT_ID.addons.qtpositioning \
        extensions.qtwebengine.$WEBENGINE_ID.clang_64 \
        qt.qt6.$QT_ID.addons.qtwebview \
        qt.qt6.$QT_ID.addons.qtwebchannel

if ! installed; then
    echo "Qt $QT_VERSION install at $PREFIX is incomplete" >&2
    exit 1
fi
echo "Installed Qt $QT_VERSION at $PREFIX"
