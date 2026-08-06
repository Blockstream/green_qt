#!/bin/bash
set -eo pipefail

curl -sL -o linuxdeploy-x86_64.AppImage https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-x86_64.AppImage
echo "421ca71d5c69ea97c6309276232990d43df1dcece0edfaa26bbf926ff96ed12e  linuxdeploy-x86_64.AppImage" | sha256sum --check
chmod +x linuxdeploy-x86_64.AppImage

curl -sL -o linuxdeploy-plugin-qt-x86_64.AppImage https://github.com/linuxdeploy/linuxdeploy-plugin-qt/releases/download/continuous/linuxdeploy-plugin-qt-x86_64.AppImage
echo "be1b7e166bf9975cfb694ebe6759ba40502ffc6196440d3e64aa90c4dbd67e9f  linuxdeploy-plugin-qt-x86_64.AppImage" | sha256sum --check
chmod +x linuxdeploy-plugin-qt-x86_64.AppImage

curl -sL -o appimagetool-x86_64.AppImage https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage
echo "a6d71e2b6cd66f8e8d16c37ad164658985e0cf5fcaa950c90a482890cb9d13e0  appimagetool-x86_64.AppImage" | sha256sum --check
chmod +x appimagetool-x86_64.AppImage
