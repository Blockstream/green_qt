import QtQuick
import QtQuick.Controls

AbstractButton {
    property bool black: false
    id: self
    focusPolicy: Qt.StrongFocus
    opacity: self.enabled ? 1 : 0.6
    icon.color: 'transparent'
    background: Item {
        Rectangle {
            border.width: 2
            border.color: Qt.alpha('#00BCFF', self.visualFocus ? 1 : 0)
            color: Qt.alpha(self.black ? '#1C1C1C' : '#FFF', (self.down ? 0.2 : 0) + (self.enabled && self.hovered ? 0.2 : 0))
            radius: width / 2
            anchors.fill: parent
            anchors.margins: -8
        }
    }
    contentItem: ColorIcon {
        color: self.icon.color
        source: self.icon.source
    }
}
