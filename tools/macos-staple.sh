#!/bin/bash
set -eox pipefail

FILE=$1
TEAM_ID=D9W37S9468
ENTITLEMENTS=$([[ $CI_COMMIT_REF_NAME = release_* ]] && echo "entitlements.plist" || echo "entitlements_debug.plist")

# resource forks and Finder info cannot be sealed, and codesign --strict rejects them.
# Clear them here, while $FILE is still unsigned, whatever route it took to this runner.
xattr -cr "$FILE"

codesign \
  --verbose=4 \
  --options runtime \
  --force \
  --entitlements $ENTITLEMENTS \
  --deep "$FILE" \
  -s "Developer ID Application: Blockstream Corporation ($TEAM_ID)"

if [[ "$FILE" = *.app ]]; then
  # V8 needs JIT in the WebEngine helper, then reseal the framework and app that contain it.
  WEBENGINE="$FILE/Contents/Frameworks/QtWebEngineCore.framework"
  codesign --verbose=4 --options runtime --force --entitlements entitlements_webengine.plist "$WEBENGINE/Versions/A/Helpers/QtWebEngineProcess.app" -s "Developer ID Application: Blockstream Corporation ($TEAM_ID)"
  codesign --verbose=4 --options runtime --force "$WEBENGINE" -s "Developer ID Application: Blockstream Corporation ($TEAM_ID)"
  codesign --verbose=4 --options runtime --force --entitlements $ENTITLEMENTS "$FILE" -s "Developer ID Application: Blockstream Corporation ($TEAM_ID)"
fi

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
