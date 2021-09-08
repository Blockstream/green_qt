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
//            Repeater {
//                model: self.icons
//                delegate: Image {
//                    source: modelData
//                    Layout.preferredWidth: 32
//                    Layout.preferredHeight: 32
//                }
//            }
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
            wrapMode: Label.WordWrap
        }
    }
    //onClicked: navigation.set({ network: self.network, type: self.type })
}
