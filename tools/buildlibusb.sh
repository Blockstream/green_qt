#!/bin/bash
set -eo pipefail

if [ -f ${LIBUSB_PATH}/build.done ]; then
    exit 0
fi

echo "LIBUSB: building with ${NUM_JOBS} cores in ${LIBUSB_PATH}"

mkdir -p ${LIBUSB_PATH}

if [ ! -d "${LIBUSB_PATH}/src" ]; then
    git clone --quiet --depth 1 --branch ${LIBUSB_TAG} --single-branch https://github.com/libusb/libusb.git ${LIBUSB_PATH}/src > ${LIBUSB_PATH}/build.log 2>&1
fi

cd ${LIBUSB_PATH}/src

./bootstrap.sh
if [ "$GREENPLATFORM" = "linux" ]; then
    ./configure --prefix=${LIBUSB_PATH} --disable-shared >> ${LIBUSB_PATH}/build.log 2>&1
elif [ "$GREENPLATFORM" = "windows" ]; then
    ./configure --host=x86_64-w64-mingw32 --prefix=${LIBUSB_PATH} --disable-shared >> ${LIBUSB_PATH}/build.log 2>&1
elif [ "$GREENPLATFORM" = "osx" ]; then
    ./configure --prefix=${LIBUSB_PATH} --disable-shared >> ${LIBUSB_PATH}/build.log 2>&1
else
    exit 1
fi

make -j${NUM_JOBS} install

touch ${LIBUSB_PATH}/build.done
