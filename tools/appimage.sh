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

cp /linuxdeploy-x86_64.AppImage .

env TARGET_APPIMAGE=linuxdeploy-x86_64.AppImage ./linuxdeploy-x86_64.AppImage --desktop-file=$SOURCE_PATH/blockstream.desktop --appdir=blockstream.AppDir --executable=blockstream --executable="$PREFIX/bin/crashpad_handler" --icon-file=$SOURCE_PATH/assets/icons/linux_production.png

# crashpad's Linux uploader dlopen()s libcurl.so.4 at runtime to POST minidumps.
# It's not a NEEDED dependency, so linuxdeploy doesn't bundle it; ship the shared
# libcurl next to crashpad_handler so the handler can load it (resolved via the
# handler's $ORIGIN RUNPATH).
cp -a "$PREFIX"/lib/libcurl.so* blockstream.AppDir/usr/bin/

if $PLUGIN_QT; then
    cp /linuxdeploy-plugin-qt-x86_64.AppImage .

    export EXTRA_QT_MODULES="waylandcompositor"
    export EXTRA_PLATFORM_PLUGINS="libqwayland.so"
    env QML_SOURCES_PATHS=$SOURCE_PATH/qml TARGET_APP_IMAGE=linuxdeploy-plugin-qt-x86_64.AppImage ./linuxdeploy-plugin-qt-x86_64.AppImage --appdir blockstream.AppDir
fi

cp /appimagetool-x86_64.AppImage .

env TARGET_APPIMAGE=appimagetool-x86_64.AppImage ./appimagetool-x86_64.AppImage --no-appstream blockstream.AppDir Blockstream-x86_64.AppImage
