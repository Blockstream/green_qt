import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Button {
    required property string server_type
    required property string type
    required property string title
    property string description
    property var icons

    id: self
    Layout.minimumHeight: 160
    Layout.preferredWidth: 360
    padding: 24
    scale: self.hovered || self.activeFocus ? 1.05 : 1
    transformOrigin: Item.Center
    Behavior on scale {
        NumberAnimation {
            easing.type: Easing.OutBack
            duration: 400
        }
    }
    background: Rectangle {
        border.width: 1
        border.color: self.activeFocus ? constants.g400 : Qt.rgba(0, 0, 0, 0.2)
        radius: 8
        color: Qt.rgba(1, 1, 1, self.hovered ? 0.1 : 0.05)
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
            Repeater {
                model: self.icons
                delegate: Image {
                    opacity: self.enabled ? 1 : 0.5
                    source: modelData
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 32
                }
            }
            Label {
                Layout.fillWidth: true
                text: self.title
                font.bold: true
                font.pixelSize: 18
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
    onClicked: navigation.set({ server_type: self.server_type })
}
