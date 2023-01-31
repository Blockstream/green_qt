import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

TextField {
    id: self
    property real radius: 4
    property var error
    readonly property bool empty: text.trim().length === 0
    bottomPadding: 6
    topPadding: 6
    leftPadding: 8
    rightPadding: 8
    font.pixelSize: 12
    selectByMouse: true
    background: Rectangle {
        implicitWidth: 200
        radius: self.radius
        opacity: self.activeFocus ? 1 : (self.enabled ? 0.8 : 0.5)
        color: constants.c500
        border.color: error ? constants.r500 : Qt.lighter(color)
        border.width: self.activeFocus ? 1 : 0
    }
}
