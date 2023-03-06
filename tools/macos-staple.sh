#!/bin/bash
set -eox pipefail

file=green.app
zip=green.zip
TEAM_ID=D9W37S9468

codesign \
  --options runtime \
  --entitlements entitlements.plist \
  --deep $file \
  -s "Developer ID Application: Blockstream Corporation ($TEAM_ID)"

ditto -c -k --keepParent $file $zip

xcrun notarytool submit -v \
  --team-id "$TEAM_ID" \
  --apple-id "${STAPLEEMAIL}" \
  --password "${STAPLEPW}" \
  --wait \
  $zip

xcrun stapler staple $file
