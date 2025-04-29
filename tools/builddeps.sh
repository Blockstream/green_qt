#!/bin/bash
set -eox pipefail

if [ -d $PREFIX ]; then
    echo "using cached depends"
    exit 0
fi

./tools/buildgdk.sh
./tools/buildbreakpad.sh
./tools/buildcrashpad.sh
./tools/buildgpgme.sh
./tools/buildlibusb.sh
./tools/buildhidapi.sh
./tools/buildcountly.sh
./tools/buildzxing.sh
./tools/buildlibserialport.sh
./tools/buildqt.sh
./tools/buildkdsingleapplication.sh

rm -rf build
