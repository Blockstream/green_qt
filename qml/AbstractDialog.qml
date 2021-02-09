import QtQuick 2.14
import QtQuick.Controls 2.14

Dialog {
    clip: true
    modal: true
    horizontalPadding: 16
    verticalPadding: 8
    anchors.centerIn: parent
    parent: Overlay.overlay
    Overlay.modal: Rectangle {
        color: '#a0080B0E'
    }
    background: Rectangle {
        radius: 8
        color: constants.c700
    }
}
