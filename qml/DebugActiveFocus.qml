import QtQuick 2.0
import QtQuick.Controls 2.13

Label {
    parent: Overlay.overlay
    anchors.bottom: parent.bottom
    anchors.right: parent.right
    anchors.margins: 4
    z: 1000
    visible: Qt.application.arguments.indexOf('--debugfocus') > 0
    background: Rectangle {
        color: Qt.rgba(1, 0, 0, 0.4)
        radius: 4
        border.width: 2
        border.color: 'black'
    }
    padding: 8
    text: '' + activeFocusItem
}
