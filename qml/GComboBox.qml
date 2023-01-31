import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ComboBox {
    id: self
    bottomPadding: 8
    topPadding: 8
    leftPadding: 6
    rightPadding: 6 + self.indicator.width + self.spacing
    font.pixelSize: 12
    background: Rectangle {
        implicitWidth: 200
        radius: 4
        opacity: self.activeFocus ? 1 : (self.enabled ? 0.8 : 0.5)
        color: constants.c500
        border.color: Qt.lighter(color)
        border.width: self.activeFocus ? 1 : 0
    }
}
