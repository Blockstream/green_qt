#!/bin/bash
set -eo pipefail

VERSION=2.0.12

if [[ -z "$CHANNEL" ]]; then
    echo "Must set CHANNEL environment variable" 1>&2
    echo "For public release set CHANNEL=latest" 1>&2
    exit 1
fi

cp ../tools/templates/channel.json ${CHANNEL}.json

sed -i -e "s/CHANNEL_STRING/${CHANNEL}/g" ${CHANNEL}.json
sed -i -e "s/VERSION_STRING/${VERSION}/g" ${CHANNEL}.json

echo $GCLOUD_KEY > .key
gcloud auth activate-service-account --key-file=.key
gsutil -h "Cache-Control: no-store" cp ${CHANNEL}.json gs://${GCLOUD_BUCKET}/desktop/

gsutil cp SHA256SUMS.asc gs://${GCLOUD_BUCKET}/desktop/${CHANNEL}/${VERSION}/
gsutil cp BlockstreamGreen-x86_64.AppImage gs://${GCLOUD_BUCKET}/desktop/${CHANNEL}/${VERSION}/
gsutil cp BlockstreamGreen-linux-x86_64.tar.gz gs://${GCLOUD_BUCKET}/desktop/${CHANNEL}/${VERSION}/
gsutil cp BlockstreamGreen-universal.dmg gs://${GCLOUD_BUCKET}/desktop/${CHANNEL}/${VERSION}/
gsutil cp BlockstreamGreen-arm64.dmg gs://${GCLOUD_BUCKET}/desktop/${CHANNEL}/${VERSION}/
gsutil cp BlockstreamGreen-x86_64.dmg gs://${GCLOUD_BUCKET}/desktop/${CHANNEL}/${VERSION}/
gsutil cp BlockstreamGreenSetup-x86_64.exe gs://${GCLOUD_BUCKET}/desktop/${CHANNEL}/${VERSION}/

rm .key
