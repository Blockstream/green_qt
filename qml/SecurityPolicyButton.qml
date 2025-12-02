import Blockstream.Green
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

AbstractButton {
    required property Network network
    required property string tag
    required property string title
    required property string description
    property bool beta: false
    property color tagColor: Qt.alpha('#FFF', 0.4)


    Layout.fillWidth: true
    id: self
    icon.source: self.network.electrum ? 'qrc:/svg2/singlesig.svg' : 'qrc:/svg2/multisig.svg'
    text: self.network.electrum ? 'singlesig' : 'multisig'
    padding: 20
    background: Item {
        Rectangle {
            anchors.fill: parent
            anchors.margins: self.visualFocus ? 4 : 0
            color: Qt.lighter('#181818', self.enabled && self.hovered ? 1.1 : 1)
            radius: self.visualFocus ? 1 : 5
        }
        Image {
            anchors.top: parent.top
            anchors.right: parent.right
            source: 'qrc:/svg2/beta.svg'
            visible: self.beta
        }
        Rectangle {
            border.width: 2
            border.color: '#00BCFF'
            color: 'transparent'
            radius: 5
            anchors.fill: parent
            visible: self.visualFocus
        }
    }
    contentItem: RowLayout {
        spacing: 20
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8
            RowLayout {
                spacing: 4
                Label {
                    Layout.alignment: Qt.AlignCenter
                    color: '#FFF'
                    font.pixelSize: 10
                    font.capitalization: Font.AllUppercase
                    font.weight: 400
                    topPadding: 4
                    bottomPadding: 4
                    leftPadding: 8
                    rightPadding: 8
                    text: self.text
                    background: Rectangle {
                        radius: height / 2
                        color: '#FFF'
                        opacity: 0.4
                    }
                }
                Label {
                    Layout.alignment: Qt.AlignCenter
                    color: '#FFF'
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
                        color: self.tagColor
                    }
                }
                HSpacer {
                }
            }
            RowLayout {
                spacing: 8
                Label {
                    color: '#FFF'
                    font.pixelSize: 16
                    font.weight: 600
                    text: self.title
                }
                Image {
                    Layout.alignment: Qt.AlignCenter
                    source: self.icon.source
                }
                HSpacer {
                }
            }
            Label {
                Layout.fillWidth: true
                color: '#FFF'
                font.pixelSize: 12
                font.weight: 400
                opacity: 0.6
                text: self.description
                wrapMode: Label.WordWrap
            }
        }
        Image {
            Layout.alignment: Qt.AlignCenter
            visible: self.enabled
            source: 'qrc:/svg2/next_arrow.svg'
        }
    }
}
