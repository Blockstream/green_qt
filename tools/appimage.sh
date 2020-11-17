#!/bin/bash
set -eox pipefail

curl -sL -o linuxdeploy-x86_64.AppImage https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-x86_64.AppImage
curl -sL -o appimagetool-x86_64.AppImage https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage
chmod +x linuxdeploy-x86_64.AppImage
chmod +x appimagetool-x86_64.AppImage

env TARGET_APPIMAGE=linuxdeploy-x86_64.AppImage APPIMAGE_EXTRACT_AND_RUN=1 ./linuxdeploy-x86_64.AppImage --desktop-file=$1/green.desktop --appdir=green.AppDir --executable=green --icon-file=$1/assets/icons/green.png
env TARGET_APPIMAGE=appimagetool-x86_64.AppImage APPIMAGE_EXTRACT_AND_RUN=1 ./appimagetool-x86_64.AppImage --no-appstream green.AppDir BlockstreamGreen-x86_64.AppImage
