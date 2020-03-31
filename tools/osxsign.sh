#!/bin/bash
set -eo pipefail

. tools/envs.env osx

codesign --options=runtime --deep ./build-osx-clang/Green.app -s "Developer ID Application: Blockstream Corporation (D9W37S9468)"
