import QtQuick 2.15
import QtQml 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

AbstractButton {
    id: self
    property string description
    padding: 24
    scale: self.down ? 0.98 : (self.hovered || self.activeFocus ? 1.05 : 1)
    transformOrigin: Item.Center
    Behavior on scale {
        NumberAnimation {
            easing.type: Easing.OutBack
            duration: 400
        }
    }
    background: Rectangle {
        border.width: self.activeFocus ? 1 : 0
        border.color: constants.c600
        radius: 8
        color: self.hovered ? constants.c500 : constants.c700
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
