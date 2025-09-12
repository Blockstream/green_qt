#!/bin/bash
set -eox pipefail

FILE=$1
TEAM_ID=D9W37S9468
ENTITLEMENTS=$([[ $CI_COMMIT_REF_NAME = release_* ]] && echo "entitlements.plist" || echo "entitlements_debug.plist")

codesign \
  --verbose=4 \
  --options runtime \
  --force \
  --entitlements $ENTITLEMENTS \
  --deep "$FILE" \
  -s "Developer ID Application: Blockstream Corporation ($TEAM_ID)"

codesign --verbose=4 --strict --verify --deep $FILE

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
