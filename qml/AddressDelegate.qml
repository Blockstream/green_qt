import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts

ItemDelegate {
    signal addressClicked(Address address)
    required property Address address

    onClicked: self.addressClicked(self.address)
    id: self
    hoverEnabled: true
    leftPadding: 20
    rightPadding: 20
    topPadding: 20
    bottomPadding: 20
    background: Item {
        Rectangle {
            anchors.fill: parent
            visible: self.hovered
            color: '#00B45A'
            opacity: 0.08
        }
        Rectangle {
            color: '#1F222A'
            width: parent.width
            height: 1
            y: parent.height - 1
        }
    }
    contentItem: RowLayout {
        spacing: 20
        ColumnLayout {
            Layout.alignment: Qt.AlignCenter
            Layout.fillWidth: false
            Layout.fillHeight: false
            spacing: 5
            Label {
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                padding: 8
                topPadding: 2
                bottomPadding: 2
                text: self.address.data.tx_count
                font.pixelSize: 16
                font.weight: 600
            }
            Label {
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                text: 'TX'
                color: '#929292'
                font.pixelSize: 12
                font.weight: 400
            }
        }
        Label {
            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
            Layout.fillWidth: true
            Layout.preferredWidth: 0
            color: '#929292'
            elide: Text.ElideRight
            text: self.address.address
            font.pixelSize: 12
            font.weight: 400
        }
        CircleButton {
            Layout.alignment: Qt.AlignCenter
            icon.source: 'qrc:/svg2/copy.svg'
            onClicked: Clipboard.copy(self.address.address)
        }
        ColumnLayout {
            Layout.alignment: Qt.AlignCenter
            Layout.fillWidth: false
            Layout.fillHeight: false
            Layout.minimumWidth: 150
            Label {
                Layout.alignment: Qt.AlignRight
                font.pixelSize: 10
                font.weight: 700
                topPadding: 2
                bottomPadding: 2
                leftPadding: 6
                rightPadding: 6
                text: localizedLabel(self.address.type)
                background: Rectangle {
                    radius:  2
                    color: '#68727D'
                }
            }
        }
    }
}
