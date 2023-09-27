import Blockstream.Green
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

AbstractButton {
    required property Network network
    required property string type
    required property string tag
    required property string title
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
            visible: self.visualFocus
        }
    }
    contentItem: RowLayout {
        spacing: 20
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8
            RowLayout {
                opacity: 0.6
                spacing: 4
                Label {
                    Layout.alignment: Qt.AlignCenter
                    font.family: 'SF Compact Display'
                    font.pixelSize: 10
                    font.capitalization: Font.AllUppercase
                    font.weight: 400
                    topPadding: 4
                    bottomPadding: 4
                    leftPadding: 8
                    rightPadding: 8
                    text: self.network.electrum ? 'singlesig' : 'multisig'
                    background: Rectangle {
                        radius: height / 2
                        color: '#FFF'
                        opacity: 0.4
                    }
                }
                Label {
                    Layout.alignment: Qt.AlignCenter
                    font.family: 'SF Compact Display'
                    font.pixelSize: 10
                    font.capitalization: Font.AllUppercase
                    font.weight: 400
                    topPadding: 4
                    bottomPadding: 4
                    leftPadding: 8
                    rightPadding: 8
                    text: self.tag
                    background: Rectangle {
                        radius: height / 2
                        color: '#FFF'
                        opacity: 0.4
                    }
                }
                HSpacer {
                }
            }
            RowLayout {
                spacing: 8
                Label {
                    font.family: 'SF Compact Display'
                    font.pixelSize: 16
                    font.weight: 600
                    text: self.title
                }
                Image {
                    Layout.alignment: Qt.AlignCenter
                    source: self.network.electrum ? 'qrc:/svg2/singlesig.svg' : 'qrc:/svg2/multisig.svg'
                }
                HSpacer {
                }
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
            source: 'qrc:/svg2/next_arrow.svg'
        }
    }
}
