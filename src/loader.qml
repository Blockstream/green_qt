import Blockstream.Green 0.1
import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Controls.Material 2.3
import QtQuick.Window 2.13


ApplicationWindow {
    property Wallet currentWallet

    visible: true
    width: 1024
    height: 680
    minimumWidth: 800
    minimumHeight: 480

    Material.accent: Material.Green
    Material.theme: Material.Dark

    Loader {
        id: loader
        anchors.fill: parent
        source: 'main.qml'

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
        visible: engine.debug
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 8
    }
}
