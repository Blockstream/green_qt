#!/bin/bash
set -eox pipefail

zip_name=green.zip

zip -r ${zip_name} Blockstream\ Green.dmg

xcrun altool --notarize-app \
               --username "${STAPLEEMAIL}" \
               --primary-bundle-id com.blockstream.Green \
               --password "${STAPLEPW}" \
               --file ${zip_name}

while :
do
  sleep 10
  xcrun altool --notarization-history 0 -u "${STAPLEEMAIL}" -p "${STAPLEPW}" | fgrep "in progress" || break
done

xcrun stapler staple Blockstream\ Green.dmg
