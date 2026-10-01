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
INSTALLER_VERSION=4.11.0
INSTALLER_SHA256=917fb4048226db081b780b751138c896165f66df523f3b0f4385bcfb4a1c59da
INSTALLER_NAME=qt-online-installer-macOS-universal-$INSTALLER_VERSION
WEBENGINE_ID=${2:-$QT_ID}
ROOT="${QT_INSTALL_ROOT:-$HOME/Qt}/$QT_VERSION"
PREFIX="$ROOT/$QT_VERSION/macos"
# Written only after a validated install, so a partial or interrupted install is never accepted.
MARKER="$ROOT/.install-complete"
EXPECTED="qt=$QT_VERSION webengine=$WEBENGINE_ID"
COMPONENTS=(
    qt.qt6.$QT_ID.clang_64
    qt.qt6.$QT_ID.addons.qt5compat
    qt.qt6.$QT_ID.addons.qtconnectivity
    qt.qt6.$QT_ID.addons.qtmultimedia
    qt.qt6.$QT_ID.addons.qtserialport
    qt.qt6.$QT_ID.addons.qtpositioning
    extensions.qtwebengine.$WEBENGINE_ID.clang_64
    qt.qt6.$QT_ID.addons.qtwebview
    qt.qt6.$QT_ID.addons.qtwebchannel
)

installed() {
    [ "$(cat "$MARKER" 2>/dev/null)" = "$EXPECTED" ]
}

validate() {
    [ "$("$PREFIX/bin/qmake" -query QT_VERSION 2>/dev/null)" = "$QT_VERSION" ] || return 1
    [ -d "$PREFIX/lib/QtWebEngineCore.framework" ] || return 1
    for c in "${COMPONENTS[@]}"; do
        grep -qF "<Name>$c</Name>" "$ROOT/components.xml" || { echo "Missing component $c" >&2; return 1; }
    done
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

curl -sSfL -o "$WORK/installer.dmg" "https://download.qt.io/archive/online_installers/${INSTALLER_VERSION%.*}/$INSTALLER_NAME.dmg"
echo "$INSTALLER_SHA256  $WORK/installer.dmg" | shasum -a 256 -c -
mkdir "$MOUNT"
hdiutil attach "$WORK/installer.dmg" -nobrowse -readonly -mountpoint "$MOUNT" -quiet
INSTALLER="$MOUNT/$INSTALLER_NAME.app/Contents/MacOS/$INSTALLER_NAME"

"$INSTALLER" \
    --root "$ROOT" \
    --accept-licenses --default-answer --confirm-command --accept-obligations \
    install "${COMPONENTS[@]}"

if ! validate; then
    echo "Qt $QT_VERSION install at $PREFIX is incomplete" >&2
    exit 1
fi
echo "$EXPECTED" > "$MARKER.tmp"
mv "$MARKER.tmp" "$MARKER"
echo "Installed Qt $QT_VERSION at $PREFIX"
