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
    width: ListView.view.width
    background: Item {
        Rectangle {
            anchors.fill: parent
            visible: self.hovered
            color: '#00BCFF'
            opacity: 0.08
        }
        Rectangle {
            color: '#1F222A'
            width: parent.width
            height: 1
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
        RowLayout {
            Layout.fillWidth: false
            Layout.maximumWidth: self.width / 7
            Layout.minimumWidth: self.width / 7
            Layout.preferredWidth: 0
            AccountLabel {
                Layout.maximumWidth: parent.width
                account: self.address.account
            }
        }
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
                text: self.address.data?.tx_count ?? '0'
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
            font.features: { 'calt': 0, 'zero': 1 }
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
            AddressTypeLabel {
                Layout.alignment: Qt.AlignRight
                address: self.address
            }
        }
    }
}
