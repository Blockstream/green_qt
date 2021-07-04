import QtQuick 2.14
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.13

Button {
    property bool large: false
    property bool destructive: false
    function _color(index) {
        const prefix = self.highlighted ? 'g' : self.destructive ? 'r' : 'c'
        return constants[prefix + index]
    }
    id: self
    font.pixelSize: self.large ? 14 : 12
    icon.width: self.large ? 16 : 12
    icon.height: self.large ? 16 : 12
    font.bold: true
    padding: self.large ? 16 : 12
    leftPadding: self.large ? 20 : 15
    rightPadding: self.large ? 20 : 15
    background: Rectangle {
        id: background
        radius: 4
        color: {
            if (!self.enabled) return _color(700)
            if (self.pressed) return 'white'
            if (self.activeFocus || self.hovered) return _color(600)
            return _color(500)
        }
        border.width: self.activeFocus ? 2 : 0
        border.color: Qt.lighter(background.color)
    }
    contentItem: RowLayout {
        spacing: self.padding
        opacity: self.enabled ? 1 : 0.5
        Image {
            visible: status === Image.Ready
            source: self.icon.source
            Layout.preferredWidth: self.icon.width
            Layout.preferredHeight: self.icon.height
        }
        Label {
            Layout.alignment: Qt.AlignCenter
            text: self.text
            color: self.pressed ? "black" : "white"
        }
    }
}
