import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

AbstractDrawer {
    signal walletClicked(Wallet wallet)
    signal deviceClicked(Device device)
    signal removeWallet(Wallet wallet)

    id: self
    dim: true
    edge: Qt.LeftEdge
    modal: false
    z: 0
    contentItem: Page {
        spacing: 10
        background: null
        header: RowLayout {
            CloseButton {
                Layout.alignment: Qt.AlignRight
                onClicked: self.close()
            }
        }
        contentItem: VFlickable {
            alignment: Qt.AlignTop
            spacing: 10
            Label {
                font.pixelSize: 14
                font.weight: 600
                opacity: 0.4
                text: qsTrId('id_digital_wallets')
            }
            Hint {
                text: 'Your wallets with keys persisted on the Blockstream app will appear here.'
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
                    onRemoveClicked: self.removeWallet(wallet_button.wallet)
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
                    id: device_button
                    onClicked: self.walletClicked(device_button.wallet)
                    onRemoveClicked: self.removeWallet(device_button.wallet)
                }
            }
            VSpacer {
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
                color: Qt.lighter('#262626', button.enabled && button.hovered ? 1.2 : 1)
                radius: button.visualFocus ? 1 : 5
                anchors.fill: parent
                anchors.margins: button.visualFocus ? 4 : 0
            }
        }
    }

    component WalletButton: ListButton {
        signal removeClicked()
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
            CircleButton {
                Layout.alignment: Qt.AlignCenter
                id: options_button
                icon.source: 'qrc:/svg/3-dots.svg'
                opacity: button.hovered || options_button.visualFocus || options_menu.visible ? 1 : 0
                onClicked: options_menu.open()
                GMenu {
                    id: options_menu
                    x: options_button.width * 0.5 - options_menu.width * 0.85
                    y: options_button.height + 8
                    pointerX: 0.85
                    pointerY: 0
                    GMenu.Item {
                        text: qsTrId('id_remove_wallet')
                        icon.source: 'qrc:/svg2/trash.svg'
                        onClicked: {
                            options_menu.close()
                            button.removeClicked()
                        }
                    }
                }
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
            RightArrowIndicator {
                active: button.hovered || options_menu.visible
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
            RightArrowIndicator {
                active: button.hovered
            }
        }
    }
}
