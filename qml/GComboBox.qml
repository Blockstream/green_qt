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
    background: Rectangle {
        implicitWidth: 200
        implicitHeight: 40
        radius: 4
        opacity: self.activeFocus ? 1 : (self.enabled ? 0.8 : 0.5)
        color: Qt.lighter('#222226', self.hovered ? 1.2 : 1)
    }
}
