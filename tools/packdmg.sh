#!/bin/bash
set -exo pipefail

rm -rf staging tmp.dmg Blockstream.dmg
cp -R tools/staging staging
cp -R "$1" staging/Blockstream.app
ln -s /Applications staging/Applications
hdiutil makehybrid -hfs -hfs-volume-name "Blockstream" -hfs-openfolder staging staging -o tmp.dmg
hdiutil convert -format UDZO tmp.dmg -o Blockstream.dmg

