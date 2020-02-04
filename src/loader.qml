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

    id: window

    property string location: '/'
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

    function alpha(index) {
        if (index % 4 === 0) return 1
        if (index % 2 === 0) return 0.5
        return 0.25
    }

    Item {
        id: grid
        visible: false
        property int size: 8
        anchors.fill: parent
        opacity: 0.1
        Repeater {
            model: Math.ceil(grid.height / grid.size)
            Rectangle { y: index * grid.size; width: grid.width; height: 1; color: 'white'; opacity: alpha(index) }
        }
        Repeater {
            model: Math.ceil(grid.width / grid.size)
            Rectangle { x: index * grid.size; height: grid.height; width: 1; color: 'white'; opacity: alpha(index) }
        }
    }

    Action {
        enabled: engine.debug
        shortcut: 'CTRL+G'
        onTriggered: grid.visible = !grid.visible
    }

    Connections {
        target: engine
        onSourceChanged: loader.reload()
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
