import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

GPane {
    id: self
    topPadding: 8
    bottomPadding: 8
    leftPadding: 24
    rightPadding: 24
    focusPolicy: Qt.ClickFocus
    background: Rectangle {
        color: constants.c800
        Rectangle {
            anchors.top: parent.top
            width: parent.width
            height: 1
            color: constants.c900
        }
    }
}
