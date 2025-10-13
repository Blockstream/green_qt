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
                    font.pixelSize: 14
                    font.weight: 600
                    opacity: 0.4
                    text: qsTrId('id_digital_wallets')
                }
                Hint {
                    text: 'Your wallets with keys persisted on the Green app will appear here.'
                    visible: sww_repeater.count === 0
                }
                Repeater {
                    id: sww_repeater
                    model: WalletListModel {
                        deviceDetails: WalletListModel.No
                    }
                    delegate: WalletButton {
                        id: wallet_button
                        onClicked: self.walletClicked(wallet_button.wallet)
                    }
                }
                Label {
                    Layout.topMargin: 20
                    font.pixelSize: 14
                    font.weight: 600
                    opacity: 0.4
                    text: qsTrId('id_hardware_devices')
                }
                Hint {
                    text: 'Your wallets with keys persisted on a hardware device will appear here.'
                    visible: hww_repeater.count === 0
                }
                Repeater {
                    id: hww_repeater
                    model: WalletListModel {
                        deviceDetails: WalletListModel.Yes
                        watchOnly: WalletListModel.No
                        pinData: WalletListModel.No
                    }
                    delegate: WalletButton {
                        id: wallet_button
                        onClicked: self.walletClicked(wallet_button.wallet)
                    }
                }
            }
        }
        footer: RowLayout {
            LinkButton {
                Layout.alignment: Qt.AlignCenter
                Layout.margins: 16
                text: 'Set up a New Wallet'
                onClicked: self.walletClicked(null)
            }
        }
    }

    component ListButton: AbstractButton {
        Layout.fillWidth: true
        id: button
        implicitHeight: 60
        leftPadding: 16
        rightPadding: 24
        background: Item {
            Rectangle {
                border.width: 2
                border.color: '#00BCFF'
                color: 'transparent'
                radius: 5
                anchors.fill: parent
                opacity: button.visualFocus ? 1 : 0
            }
            Rectangle {
                color: Qt.lighter('#222226', button.enabled && button.hovered ? 1.2 : 1)
                radius: button.visualFocus ? 1 : 5
                anchors.fill: parent
                anchors.margins: button.visualFocus ? 4 : 0
            }
        }
    }

    component WalletButton: ListButton {
        required property Wallet wallet
        id: button
        contentItem: RowLayout {
            spacing: 14
            Image {
                Layout.alignment: Qt.AlignCenter
                source: {
                    if (button.wallet.login instanceof WatchonlyData) {
                        return 'qrc:/svg2/eye.svg'
                    } else if (button.wallet.deployment !== 'mainnet') {
                        return 'qrc:/svg2/flask.svg'
                    } else {
                        return 'qrc:/svg2/wallet.svg'
                    }
                }
            }
            Label {
                Layout.alignment: Qt.AlignCenter
                Layout.fillWidth: true
                Layout.preferredWidth: 0
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
                visible: button.wallet.login?.device ?? false
                source: {
                    switch (button.wallet.login?.device?.type) {
                    case 'jade':
                        return 'qrc:/svg2/jade-logo.svg'
                    case 'nanos':
                    case 'nanox':
                        return 'qrc:/svg2/ledger-logo.svg'
                    default:
                        return ''
                    }
                }
            }
            Image {
                Layout.alignment: Qt.AlignCenter
                source: 'qrc:/svg2/right.svg'
            }
        }
    }

    component DeviceButton: ListButton {
        required property Device device
        id: button
        contentItem: RowLayout {
            spacing: 14
            Label {
                Layout.alignment: Qt.AlignCenter
                Layout.fillWidth: true
                Layout.preferredWidth: 0
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
    }
}
