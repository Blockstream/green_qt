#!/bin/bash

set -exo pipefail

APP_NAME="Blockstream"
APP_BUNDLE="Blockstream.app"
DMG_NAME="Blockstream"
VOLUME_NAME="Blockstream"
BACKGROUND_IMG="assets/background.tiff"

STAGING_DIR="./dmg-staging"
DMG_TMP="temp.dmg"
DMG_FINAL="$DMG_NAME.dmg"

rm -rf "$STAGING_DIR" "$DMG_TMP" "$DMG_FINAL"

mkdir "$STAGING_DIR"
cp -R "$1" "$STAGING_DIR/$APP_BUNDLE"
ln -s /Applications "$STAGING_DIR/Applications"
mkdir "$STAGING_DIR/.background"
cp "$BACKGROUND_IMG" "$STAGING_DIR/.background/"

hdiutil create -srcfolder "$STAGING_DIR" -volname "$VOLUME_NAME" -fs HFS+ -fsargs "-c c=64,a=16,e=16" -format UDRW "$DMG_TMP"

MOUNT_DIR="/Volumes/$VOLUME_NAME"
hdiutil attach "$DMG_TMP" -mountpoint "$MOUNT_DIR"

sleep 1

osascript <<EOF
tell application "Finder"
  tell disk "$VOLUME_NAME"
    open
      delay 1
      set current view of container window to icon view
      set theViewOptions to the icon view options of container window
      set background picture of theViewOptions to file ".background:background.tiff"
      set arrangement of theViewOptions to not arranged
      set icon size of theViewOptions to 84
      delay 1
    close
    open
    delay 1
      update without registering applications
      tell container window
        set sidebar width to 0
        set statusbar visible to false
        set toolbar visible to false
        set the bounds to { 400, 100, 892, 545 }
        set position of item "$APP_BUNDLE" to { 123, 312 }
        set position of item "Applications" to { 369, 312 }
      end tell
      update without registering applications
      delay 1
    close
  end tell
end tell
EOF

bless --folder "$MOUNT_DIR"
sleep 10
hdiutil detach "$MOUNT_DIR"
hdiutil convert "$DMG_TMP" -format UDZO -imagekey zlib-level=9 -o "$DMG_FINAL"
rm -rf "$STAGING_DIR" "$DMG_TMP"
