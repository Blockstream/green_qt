#!/bin/bash
set -eox pipefail

if [ -d $PREFIX ]; then
    echo "using cached depends"
    exit 0
fi

./tools/buildbreakpad.sh
./tools/buildgpgme.sh
./tools/buildgdk.sh
./tools/buildqt.sh
./tools/buildlibusb.sh
./tools/buildhidapi.sh
./tools/buildcountly.sh
./tools/buildkdsingleapplication.sh
./tools/buildzxing.sh
./tools/buildlibserialport.sh
./tools/buildcrashpad.sh

rm -rf build
