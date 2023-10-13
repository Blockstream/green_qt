import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ComboBox {
    id: self
    bottomPadding: 10
    topPadding: 10
    leftPadding: 10
    rightPadding: 10 + self.indicator.width + self.spacing
    font.family: 'SF Compact Display'
    font.pixelSize: 14
    font.weight: 600
    background: Rectangle {
        implicitWidth: 200
        implicitHeight: 40
        radius: 4
        opacity: self.activeFocus ? 1 : (self.enabled ? 0.8 : 0.5)
        color: constants.c500
        border.color: Qt.lighter(color)
        border.width: self.activeFocus ? 1 : 0
    }
}
