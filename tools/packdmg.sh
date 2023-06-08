#!/bin/bash
set -eo pipefail

rm -rf staging tmp.dmg Blockstream\ Green.dmg
cp -R tools/staging staging
cp -R "$1" staging/Blockstream\ Green.app
ln -s /Applications staging/Applications
hdiutil makehybrid -hfs -hfs-volume-name "Blockstream Green" -hfs-openfolder staging staging -o tmp.dmg
hdiutil convert -format UDZO tmp.dmg -o Blockstream\ Green.dmg

