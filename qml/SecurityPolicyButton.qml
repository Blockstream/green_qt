import Blockstream.Green
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

AbstractButton {
    required property string title
    required property string type
    required property string description

    id: self
    padding: 20
    background: Rectangle {
        color: '#222226'
        radius: 5
        Rectangle {
            border.width: 2
            border.color: '#00B45A'
            color: 'transparent'
            radius: 9
            anchors.fill: parent
            anchors.margins: -4
            opacity: self.visualFocus ? 1 : 0
        }
    }
    contentItem: RowLayout {
        spacing: 10
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            RowLayout {
                spacing: 4
                opacity: 0.6
                Image {
                    source: self.icon.source
                    Layout.preferredHeight: 16
                    Layout.preferredWidth: 16
                }
                Label {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignCenter
                    font.family: 'SF Compact Display'
                    font.pixelSize: 10
                    font.weight: 400
                    text: self.type
                }
            }
            Label {
                font.family: 'SF Compact Display'
                font.pixelSize: 16
                font.weight: 600
                text: self.title
            }
            Item {
                Layout.minimumHeight: 10
            }
            Label {
                Layout.fillWidth: true
                font.family: 'SF Compact Display'
                font.pixelSize: 12
                font.weight: 400
                opacity: 0.6
                text: self.description
                wrapMode: Label.WordWrap
            }
        }
        Image {
            Layout.alignment: Qt.AlignCenter
            sourceSize.height: 32
            sourceSize.width: 32
            source: 'qrc:/svg/arrow_right.svg'
        }
    }
}
