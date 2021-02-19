#!/bin/bash
set -eo pipefail

. tools/envs.env $1 $2

if [ "${BUILDDIR}" = "" ]; then
    echo "Unsupported target"
    exit 1
fi

mkdir -p ${BUILDROOT}

echo "Building in ${BUILDROOT}"

QZXING_COMMIT=8bed4366748d995011e7e8b25671b37d4feb783f
QZXING_BRANCH=mirror

if [ ! -d "${BUILDROOT}/qzxing" ]; then
    git clone --quiet --depth 1 --single-branch --branch ${QZXING_BRANCH} https://github.com/Blockstream/qzxing.git ${BUILDROOT}/qzxing
    (cd ${BUILDROOT}/qzxing &&
    git checkout ${QZXING_COMMIT})
fi

./tools/buildlibusb.sh || (cat ${LIBUSB_PATH}/build.log && false)
echo "LIBUSB: OK"
./tools/buildqt.sh || (cat ${QT_PATH}/build.log && false)
echo "Qt: OK"
./tools/buildgdk.sh || (cat ${GDK_PATH}/build.log && false)
echo "GDK: OK"
