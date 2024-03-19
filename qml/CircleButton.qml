import QtQuick
import QtQuick.Controls

AbstractButton {
    HoverHandler {
        cursorShape: Qt.PointingHandCursor
    }
    id: self
    focusPolicy: Qt.StrongFocus
    opacity: self.enabled ? 1 : 0.6
    background: Item {
        Rectangle {
            border.width: 2
            border.color: Qt.alpha('#00B45A', self.visualFocus ? 1 : 0)
            color: Qt.alpha('#FFF', (self.down ? 0.2 : 0) + (self.enabled && self.hovered ? 0.2 : 0))
            radius: width / 2
            anchors.fill: parent
            anchors.margins: -8
        }
    }
    contentItem: Image {
        source: self.icon.source
    }
}
