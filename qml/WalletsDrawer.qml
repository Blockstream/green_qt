import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

AbstractDrawer {
    signal walletClicked(Wallet wallet)
    signal deviceClicked(Device device)

    id: self
    dim: true
    modal: false
    edge: Qt.LeftEdge
    contentItem: Page {
        spacing: 10
        background: null
        header: RowLayout {
            CloseButton {
                Layout.alignment: Qt.AlignRight
                onClicked: self.close()
            }
        }
        contentItem: Flickable {
            id: flickable
            clip: true
            contentHeight: layout.implicitHeight
            contentWidth: flickable.width
            ScrollIndicator.vertical: ScrollIndicator {
            }
            ColumnLayout {
                id: layout
                spacing: 10
                width: flickable.width
                Label {
                    font.family: 'SF Compact Display'
                    font.pixelSize: 14
                    font.weight: 600
                    opacity: 0.4
                    text: qsTrId('id_digital_wallets')
                }
                Repeater {
                    model: WalletListModel {
                    }
                    WalletButton {
                    }
                }
                Label {
                    Layout.topMargin: 20
                    font.family: 'SF Compact Display'
                    font.pixelSize: 14
                    font.weight: 600
                    opacity: 0.4
                    text: qsTrId('id_hardware_devices')
                }
                Repeater {
                    model: DeviceListModel {
                    }
                    DeviceButton {
                    }
                }
            }
        }
        footer: RowLayout {
            LinkButton {
                Layout.alignment: Qt.AlignCenter
                Layout.margins: 16
                text: qsTrId('id_setup_a_new_wallet')
                onClicked: self.walletClicked(null)
            }
        }
    }
    component WalletButton: AbstractButton {
        required property Wallet wallet
        Layout.fillWidth: true
        id: button
        implicitHeight: 60
        leftPadding: 16
        rightPadding: 24
        background: Rectangle {
            color: '#222226'
            radius: 5
            Rectangle {
                border.width: 2
                border.color: '#00B45A'
                color: 'transparent'
                radius: 12
                anchors.fill: parent
                anchors.margins: -4
                z: -1
                opacity: button.visualFocus ? 1 : 0
            }
        }
        contentItem: RowLayout {
            spacing: 14
            Label {
                Layout.alignment: Qt.AlignCenter
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                font.family: 'SF Compact Display'
                font.pixelSize: 14
                font.weight: 500
                text: button.wallet.name
                elide: Label.ElideRight
            }
            Rectangle {
                Layout.alignment: Qt.AlignCenter
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                implicitHeight: 10
                implicitWidth: 10
                color: '#42FF00'
                radius: 5
                visible: !!button.wallet.context
            }
            Image {
                Layout.alignment: Qt.AlignCenter
                source: 'qrc:/svg2/right.svg'
            }
        }
        onClicked: self.walletClicked(button.wallet)
    }

    component DeviceButton: AbstractButton {
        required property Device device
        Layout.fillWidth: true
        id: button
        implicitHeight: 60
        leftPadding: 16
        rightPadding: 24
        background: Rectangle {
            color: '#222226'
            radius: 5
            Rectangle {
                border.width: 2
                border.color: '#00B45A'
                color: 'transparent'
                radius: 12
                anchors.fill: parent
                anchors.margins: -4
                z: -1
                opacity: button.visualFocus ? 1 : 0
            }
        }
        contentItem: RowLayout {
            spacing: 14
            Label {
                Layout.alignment: Qt.AlignCenter
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                font.family: 'SF Compact Display'
                font.pixelSize: 14
                font.weight: 500
                text: button.device.name
                elide: Label.ElideRight
            }
            Rectangle {
                Layout.alignment: Qt.AlignCenter
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                implicitHeight: 10
                implicitWidth: 10
                color: button.device.connected ? '#42FF00' : 'red'
                radius: 5
            }
            Image {
                Layout.alignment: Qt.AlignCenter
                source: button.device.vendor === Device.Blockstream ? 'qrc:/svg2/jade-logo.svg' : 'qrc:/svg2/ledger-logo.svg'
            }
            Image {
                Layout.alignment: Qt.AlignCenter
                source: 'qrc:/svg2/right.svg'
            }
        }
        onClicked: self.deviceClicked(button.device)
    }
}
