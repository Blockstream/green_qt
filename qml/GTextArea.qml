import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

TextArea {
    id: self
    bottomPadding: 8
    topPadding: 8
    leftPadding: 8
    rightPadding: 8
    background: Rectangle {
        implicitWidth: 200
        radius: 4
        opacity: self.activeFocus ? 1 : (self.enabled ? 0.8 : 0.5)
        color: 'transparent'
        border.color: self.activeFocus ? constants.g500 : constants.c500
        border.width: self.activeFocus ? 1.5 : 0.5
    }
}
