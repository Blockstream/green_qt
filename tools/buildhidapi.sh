#!/bin/bash
set -eo pipefail

if [ -f ${HIDAPI_PATH}/build.done ]; then
    exit 0
fi

echo "HIDAPI: building with ${NUM_JOBS} cores in ${HIDAPI_PATH}"

mkdir -p ${HIDAPI_PATH}

if [ ! -d "${HIDAPI_PATH}/src" ]; then
    git clone --quiet --depth 1 --branch ${HIDAPI_TAG} --single-branch https://github.com/libusb/hidapi.git ${HIDAPI_PATH}/src > ${HIDAPI_PATH}/build.log 2>&1
fi

cd ${HIDAPI_PATH}/src

# Remove duplicate AC_CONFIG_MACRO_DIR
# see https://github.com/libusb/hidapi/commit/d15d594a415e5f51d2cd8ff8bb77b3765a539b98
# (can be removed when hidapi is updated)
sed -i.bak '16d' configure.ac

./bootstrap
if [ "$GREENPLATFORM" = "linux" ]; then
    PKG_CONFIG_PATH=${LIBUSB_PATH}/lib/pkgconfig ./configure --prefix=${HIDAPI_PATH} >> ${HIDAPI_PATH}/build.log 2>&1
elif [ "$GREENPLATFORM" = "windows" ]; then
    ./configure --host=x86_64-w64-mingw32 --prefix=${HIDAPI_PATH} >> ${HIDAPI_PATH}/build.log 2>&1
elif [ "$GREENPLATFORM" = "osx" ]; then
    ./configure --prefix=${HIDAPI_PATH} >> ${HIDAPI_PATH}/build.log 2>&1
else
    exit 1
fi

make -j${NUM_JOBS} install

touch ${HIDAPI_PATH}/build.done
