import QtQuick
import QtQuick.Controls

AbstractButton {
    id: self
    background: Item {
        Rectangle {
            border.width: 2
            border.color: Qt.alpha('#00B45A', self.visualFocus ? 1 : 0)
            color: Qt.alpha('#FFF', (self.down ? 0.2 : 0) + (self.hovered ? 0.2 : 0))
            radius: width / 2
            anchors.fill: parent
            anchors.margins: -8
        }
    }
    contentItem: Image {
        source: 'qrc:/svg2/refresh.svg'
    }
}
