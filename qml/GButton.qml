import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Button {
    property bool large: false
    property bool destructive: false
    property var baseColor
    property var textColor: self.pressed ? "black" : "white"
    function _color(index) {
        if (baseColor) {
            return Qt.lighter(baseColor, 1 + 0.001 * index)
        } else {
            const colors = self.highlighted
                ? { 500: '#00B45A', 600: '#00a550', 700: '#009244' }
                : self.destructive
                    ? { 500: '#69302E', 600: '#612B29', 700: '#341817' }
                    : { 500: '#273545', 600: '#23303E', 700: '#19222C' }
            return colors[index]
        }
    }
    id: self
    topInset: 0
    bottomInset: 0
    font.pixelSize: self.large ? 14 : 12
    icon.width: self.large ? 16 : 12
    icon.height: self.large ? 16 : 12
    icon.color: 'transparent'
    font.bold: true
    font.weight: 600
    topPadding: self.large ? 10 : 6
    bottomPadding: self.large ? 10 : 6
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
        border.width: self.activeFocus ? 1 : 0
        border.color: Qt.lighter(background.color)
    }
    contentItem: RowLayout {
        spacing: self.padding
        opacity: self.enabled ? 1 : 0.5
        ColorIcon {
            visible: status === Image.Ready
            color: self.icon.color
            source: self.icon.source
            Layout.preferredWidth: self.icon.width
            Layout.preferredHeight: self.icon.height
        }
        Label {
            Layout.alignment: Qt.AlignCenter
            visible: self.text !== ''
            text: self.text
            color: self.textColor
        }
    }
    Keys.onReturnPressed: clicked()
    Keys.onEnterPressed: clicked()
}
