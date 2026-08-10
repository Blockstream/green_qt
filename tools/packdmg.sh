#!/bin/bash
set -exo pipefail

APP=$1

if [ -z "$APP" ]; then
    echo "usage: $0 <bundle>" >&2
    exit 1
fi

VOLUME_NAME="Blockstream"
MOUNT_DIR="$PWD/dmg-mount"

rm -rf staging tmp.dmg rw.dmg Blockstream.dmg "$MOUNT_DIR"

# ditto rather than cp -R: cp preserves extended attributes and resource forks from the
# incoming bundle, and codesign --strict rejects both.
ditto --norsrc --noextattr --noacl tools/staging staging
ditto --norsrc --noextattr --noacl "$APP" staging/Blockstream.app
ln -s /Applications staging/Applications

hdiutil makehybrid -hfs -hfs-volume-name "$VOLUME_NAME" -hfs-openfolder staging staging -o tmp.dmg

# makehybrid synthesises com.apple.FinderInfo on every entry it writes into the HFS+
# catalogue, so the app inside the image picks up xattrs the signature never sealed and
# `codesign --verify --deep --strict` fails on it -- even though the bundle we signed was
# clean. Strip them back off through a read-write round trip. Only the bundle is cleaned:
# the volume root keeps its FinderInfo, which is where -hfs-openfolder lives.
hdiutil convert -format UDRW tmp.dmg -o rw.dmg
mkdir -p "$MOUNT_DIR"
trap 'hdiutil detach "$MOUNT_DIR" || true' EXIT
hdiutil attach -nobrowse -mountpoint "$MOUNT_DIR" rw.dmg
xattr -rd com.apple.FinderInfo "$MOUNT_DIR/Blockstream.app"
hdiutil detach "$MOUNT_DIR"
trap - EXIT

hdiutil convert -format UDZO -imagekey zlib-level=9 rw.dmg -o Blockstream.dmg

# verify the bundle as it ships, inside the final image
trap 'hdiutil detach "$MOUNT_DIR" || true' EXIT
hdiutil attach -readonly -nobrowse -mountpoint "$MOUNT_DIR" Blockstream.dmg
codesign --verify --verbose=2 --strict --deep "$MOUNT_DIR/Blockstream.app"
hdiutil detach "$MOUNT_DIR"
trap - EXIT

rm -rf staging tmp.dmg rw.dmg "$MOUNT_DIR"
