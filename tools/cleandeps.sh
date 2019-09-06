#!/bin/bash
set -eo pipefail
cd gdk
./tools/clean.sh
cd ..
rm -fr build-*/qt-release*
rm -fr build-*/gdk-*
