import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ComboBox {
    id: self
    bottomPadding: 10
    topPadding: 10
    leftPadding: 20
    rightPadding: 20 + self.indicator.width + self.spacing
    font.pixelSize: 14
    font.weight: 600
    background: Item {
        implicitWidth: 200
        implicitHeight: 48
        Rectangle {
            radius: self.visualFocus ? 4 : 8
            opacity: self.activeFocus ? 1 : (self.enabled ? 0.8 : 0.5)
            color: Qt.lighter('#222226', self.hovered ? 1.2 : 1)
            anchors.fill: parent
            anchors.margins: self.visualFocus ? 4 : 0
        }
        Rectangle {
            border.width: 2
            border.color: '#00B45A'
            color: 'transparent'
            radius: 8
            anchors.fill: parent
            opacity: self.visualFocus ? 1 : 0
        }
    }
}
