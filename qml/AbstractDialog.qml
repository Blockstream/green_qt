import QtQuick 2.14
import QtQuick.Controls 2.14
import QtQuick.Layouts 1.13

Dialog {
    clip: true
    modal: true
    horizontalPadding: 16
    verticalPadding: 8
    anchors.centerIn: parent
    parent: Overlay.overlay
    header: RowLayout {
        Label {
            leftPadding: 16
            rightPadding: 16
            topPadding: 8
            text: title
            font.styleName: 'Light'
            font.pixelSize: 20
        }
    }
    Overlay.modal: Rectangle {
        color: '#a0080B0E'
    }
    background: Rectangle {
        radius: 8
        color: constants.c700
    }
}
