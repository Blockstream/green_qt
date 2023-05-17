#!/bin/bash
set -eox pipefail

FILE=$1
TEAM_ID=D9W37S9468

codesign \
  --options runtime \
  --entitlements entitlements.plist \
  --deep "$FILE" \
  -s "Developer ID Application: Blockstream Corporation ($TEAM_ID)"

ditto -c -k --keepParent "$FILE" "$FILE.zip"

xcrun notarytool submit \
  --verbose \
  --output-format json \
  --team-id "$TEAM_ID" \
  --apple-id "${STAPLEEMAIL}" \
  --password "${STAPLEPW}" \
  --wait \
  "$FILE.zip" | tee submission.json

xcrun notarytool log \
  --team-id "$TEAM_ID" \
  --apple-id "${STAPLEEMAIL}" \
  --password "${STAPLEPW}" \
  $(jq -r .id submission.json)

xcrun stapler staple "$FILE"
