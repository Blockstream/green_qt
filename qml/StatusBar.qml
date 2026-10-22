import QtQuick

GPane {
    id: self
    topPadding: 8
    bottomPadding: 8
    leftPadding: 24
    rightPadding: 24
    focusPolicy: Qt.ClickFocus
    background: Rectangle {
        color: '#12171E'
        Rectangle {
            anchors.top: parent.top
            width: parent.width
            height: 1
            color: '#080B0E'
        }
    }
}
