#!/bin/bash
set -eo pipefail

TOP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd .. && pwd)"
VERSION=$(grep -Eo 'project\(.*VERSION [0-9]+\.[0-9]+\.[0-9]+' $TOP_DIR/CMakeLists.txt | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+')

if [[ -z "$CHANNEL" ]]; then
    echo "Must set CHANNEL environment variable" 1>&2
    echo "For public release set CHANNEL=latest" 1>&2
    exit 1
fi

echo Publishing version $VERSION to channel $CHANNEL

cp ../tools/templates/channel.json ${CHANNEL}.json

sed -i -e "s/CHANNEL_STRING/${CHANNEL}/g" ${CHANNEL}.json
sed -i -e "s/VERSION_STRING/${VERSION}/g" ${CHANNEL}.json

echo $GCLOUD_KEY > .key
gcloud auth activate-service-account --key-file=.key
gsutil -h "Cache-Control: no-store" cp ${CHANNEL}.json gs://${GCLOUD_BUCKET}/desktop/

gsutil cp SHA256SUMS.asc gs://${GCLOUD_BUCKET}/desktop/${CHANNEL}/${VERSION}/
gsutil cp Blockstream-x86_64.AppImage gs://${GCLOUD_BUCKET}/desktop/${CHANNEL}/${VERSION}/
gsutil cp Blockstream-universal.dmg gs://${GCLOUD_BUCKET}/desktop/${CHANNEL}/${VERSION}/
gsutil cp Blockstream-arm64.dmg gs://${GCLOUD_BUCKET}/desktop/${CHANNEL}/${VERSION}/
gsutil cp Blockstream-x86_64.dmg gs://${GCLOUD_BUCKET}/desktop/${CHANNEL}/${VERSION}/
gsutil cp BlockstreamSetup-x86_64.exe gs://${GCLOUD_BUCKET}/desktop/${CHANNEL}/${VERSION}/

rm .key
