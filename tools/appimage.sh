#!/bin/bash
set -eox pipefail

PLUGIN_QT=false
SOURCE_PATH=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --plugin-qt)
            PLUGIN_QT=true
            shift
            ;;
        --*)
            echo "Unknown argument: $1"
            exit 1
            ;;
	*)
            SOURCE_PATH="$1"
	    shift
            ;;
    esac
done

if [[ -z "$SOURCE_PATH" ]]; then
    echo "Usage: $0 [--plugin-qt] <source-path>"
    exit 1
fi

export APPIMAGE_EXTRACT_AND_RUN=1

curl -sL -o linuxdeploy-x86_64.AppImage https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-x86_64.AppImage
chmod +x linuxdeploy-x86_64.AppImage

env TARGET_APPIMAGE=linuxdeploy-x86_64.AppImage ./linuxdeploy-x86_64.AppImage --desktop-file=$SOURCE_PATH/blockstream.desktop --appdir=blockstream.AppDir --executable=blockstream --icon-file=$SOURCE_PATH/assets/icons/linux_production.png

if $PLUGIN_QT; then
    curl -sL -o linuxdeploy-plugin-qt-x86_64.AppImage https://github.com/linuxdeploy/linuxdeploy-plugin-qt/releases/download/continuous/linuxdeploy-plugin-qt-x86_64.AppImage
    chmod +x linuxdeploy-plugin-qt-x86_64.AppImage

    env QML_SOURCES_PATHS=$SOURCE_PATH/qml TARGET_APP_IMAGE=linuxdeploy-plugin-qt-x86_64.AppImage ./linuxdeploy-plugin-qt-x86_64.AppImage --appdir blockstream.AppDir
fi

curl -sL -o appimagetool-x86_64.AppImage https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage
chmod +x appimagetool-x86_64.AppImage

env TARGET_APPIMAGE=appimagetool-x86_64.AppImage ./appimagetool-x86_64.AppImage --no-appstream blockstream.AppDir Blockstream-x86_64.AppImage
