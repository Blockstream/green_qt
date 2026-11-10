#!/bin/bash
set -eo pipefail

curl -sL -o linuxdeploy-x86_64.AppImage https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-x86_64.AppImage
echo "df908b19f1ed1cdafa79508d415aa12d6c56ce4d56d4149aa8c09286718706e5  linuxdeploy-x86_64.AppImage" | sha256sum --check
chmod +x linuxdeploy-x86_64.AppImage

curl -sL -o linuxdeploy-plugin-qt-x86_64.AppImage https://github.com/linuxdeploy/linuxdeploy-plugin-qt/releases/download/continuous/linuxdeploy-plugin-qt-x86_64.AppImage
echo "cfc1055b2b9dbc08412b579f20990b7b41a17b61beaa5847dc9477c96c9e9617  linuxdeploy-plugin-qt-x86_64.AppImage" | sha256sum --check
chmod +x linuxdeploy-plugin-qt-x86_64.AppImage

curl -sL -o appimagetool-x86_64.AppImage https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage
echo "e8c1169c4af66c3184d7ee110713d4be04befe671fa358e2c1591ee840553b03  appimagetool-x86_64.AppImage" | sha256sum --check
chmod +x appimagetool-x86_64.AppImage
