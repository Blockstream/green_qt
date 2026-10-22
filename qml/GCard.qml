import QtQuick
import QtQml
import QtQuick.Controls
import QtQuick.Layouts

AbstractButton {
    id: self
    property string description
    padding: 24
    background: Rectangle {
        border.width: self.activeFocus ? 1 : 0
        border.color: '#23303E'
        radius: 8
        color: self.hovered ? '#273545' : '#19222C'
        Behavior on color {
            ColorAnimation {
                duration: 300
            }
        }
    }
    contentItem: ColumnLayout {
        spacing: 12
        RowLayout {
            spacing: 12
            Label {
                Layout.fillWidth: true
                text: self.text
                font.bold: true
                font.pixelSize: 20
            }
        }
        Label {
            Layout.fillWidth: true
            Layout.fillHeight: true
            text: self.description
            font.pixelSize: 12
            wrapMode: Text.WordWrap
        }
    }
}
