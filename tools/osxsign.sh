#!/bin/bash
set -eo pipefail

codesign --options runtime --entitlements ../entitlements.plist --deep Blockstream\ Green.app -s "Developer ID Application: Blockstream Corporation (D9W37S9468)"
