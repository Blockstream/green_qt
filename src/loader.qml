import Blockstream.Green 0.1
import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Controls.Material 2.3
import QtQuick.Window 2.13


ApplicationWindow {
    FontLoader {
        id: dinpro;
        source: "assets/fonts/DINPro/DINPro-Regular.otf"
    }

    Material.accent: Material.Green
    Material.theme: Material.Dark

    id: window
    property Wallet currentWallet

    Loader {
        id: loader
        anchors.fill: parent
        source: 'main.qml'
        focus: true

        function reload() {
            const src = source
            source = ''
            engine.clearCache();
            source = src
        }
    }

    Action {
        enabled: engine.debug
        shortcut: 'CTRL+R'
        onTriggered: loader.reload()
    }

    DebugActiveFocus {
        visible: false && engine.debug
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 8
    }
}
