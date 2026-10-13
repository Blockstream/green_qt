import QtQuick

Item {
    required property color value
    required property color borderColor

    id: self
    implicitWidth: 72
    implicitHeight: 48
    clip: true

    Grid {
        anchors.fill: parent
        columns: 6
        visible: self.value.a < 1
        Repeater {
            model: 24
            Rectangle {
                required property int index
                width: self.width / 6
                height: self.height / 4
                color: (Math.floor(index / 6) + index % 6) % 2 ? '#a0a0a0' : '#ffffff'
            }
        }
    }
    Rectangle {
        anchors.fill: parent
        color: self.value
        border.width: 1
        border.color: self.borderColor
    }
}
