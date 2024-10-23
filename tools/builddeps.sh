#!/bin/bash
set -eox pipefail

if [ -d $PREFIX ]; then
    echo "using cached depends"
    exit 0
fi

./tools/buildqt.sh
./tools/buildgdk.sh
./tools/buildlibusb.sh
./tools/buildhidapi.sh
./tools/buildcountly.sh
./tools/buildkdsingleapplication.sh
./tools/buildzxing.sh
./tools/buildlibserialport.sh

rm -rf build
