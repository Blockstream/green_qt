#!/bin/bash
set -eo pipefail

TOP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd .. && pwd)"
VERSION=$(grep -Eo 'set\(BLOCKSTREAM_VERSION "[0-9]+\.[0-9]+\.[0-9]+"' $TOP_DIR/cmake/ProjectMeta.cmake | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+')

if [[ -z "$CHANNEL" ]]; then
    echo "Must set CHANNEL environment variable" 1>&2
    echo "For public release set CHANNEL=latest" 1>&2
    exit 1
fi

if [[ -z "$GCLOUD_BUCKET" ]]; then
    echo "Must set GCLOUD_BUCKET environment variable" 1>&2
    exit 1
fi

DEST_BASE="gs://${GCLOUD_BUCKET}/desktop"
DEST_VERSION="${DEST_BASE}/${CHANNEL}/${VERSION}"

echo "Publishing version ${VERSION} to channel ${CHANNEL}"

cp ../tools/templates/channel.json ${CHANNEL}.json

sed -i -e "s/CHANNEL_STRING/${CHANNEL}/g" ${CHANNEL}.json
sed -i -e "s/VERSION_STRING/${VERSION}/g" ${CHANNEL}.json

gcloud storage cp --cache-control="no-store" "${CHANNEL}.json" "${DEST_BASE}/"

gcloud storage cp SHA256SUMS.asc "${DEST_VERSION}/"
gcloud storage cp Blockstream-x86_64.AppImage "${DEST_VERSION}/"
gcloud storage cp Blockstream-universal.dmg "${DEST_VERSION}/"
gcloud storage cp Blockstream-arm64.dmg "${DEST_VERSION}/"
gcloud storage cp Blockstream-x86_64.dmg "${DEST_VERSION}/"
gcloud storage cp BlockstreamSetup-x86_64.exe "${DEST_VERSION}/"
