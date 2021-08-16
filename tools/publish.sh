#!/bin/bash
set -eo pipefail

source ../version.pri

VERSION=${VERSION_MAJOR}.${VERSION_MINOR}.${VERSION_PATCH}

HASH_WINDOWS=`cat SHA256SUMS.asc | grep Windows | awk '{split($0, a," "); print a[1]}'`
HASH_MAC=`cat SHA256SUMS.asc | grep Mac | awk '{split($0, a," "); print a[1]}'`
HASH_LINUX=`cat SHA256SUMS.asc | grep AppImage | awk '{split($0, a," "); print a[1]}'`


if [[ -z "$CHANNEL" ]]; then
    echo "Must set CHANNEL environment variable" 1>&2
    echo "For public release set CHANNEL=latest" 1>&2
    exit 1
fi

cp ../tools/templates/channel.json ${CHANNEL}.json

sed -i -e "s/VERSION_STRING/${VERSION}/g" ${CHANNEL}.json
sed -i -e "s/HASH_WINDOWS/${HASH_WINDOWS}/g" ${CHANNEL}.json
sed -i -e "s/HASH_MAC/${HASH_MAC}/g" ${CHANNEL}.json
sed -i -e "s/HASH_LINUX/${HASH_LINUX}/g" ${CHANNEL}.json

echo $GCLOUD_KEY > .key
gcloud auth activate-service-account --key-file=.key
gsutil cp -h "Cache-Control: no-store" ${CHANNEL}.json gs://${GCLOUD_BUCKET}/desktop/

gsutil cp SHA256SUMS.asc gs://${GCLOUD_BUCKET}/desktop/${VERSION}/
gsutil cp BlockstreamGreen_Windows_x86_64.zip gs://${GCLOUD_BUCKET}/desktop/${VERSION}/
gsutil cp BlockstreamGreen_MacOS_x86_64.zip gs://${GCLOUD_BUCKET}/desktop/${VERSION}/
gsutil cp BlockstreamGreen-x86_64.AppImage gs://${GCLOUD_BUCKET}/desktop/${VERSION}/

rm .key
