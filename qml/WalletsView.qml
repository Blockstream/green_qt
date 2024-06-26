import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

import "analytics.js" as AnalyticsJS
import "util.js" as UtilJS

MainPage {
    signal openWallet(Wallet wallet)
    signal openDevice(Device device)
    signal createWallet
    readonly property int count: sww_repeater.count + hww_repeater.count
    readonly property var notifications: UtilJS.flatten(home_alert.notification)
    AnalyticsAlert {
        id: home_alert
        screen: 'Home'
    }
    id: self
    padding: 60
    title: qsTrId('id_wallets')
    contentItem: Flickable {
        ScrollIndicator.vertical: ScrollIndicator {
        }
        id: flickable
        clip: true
        contentHeight: layout.height
        contentWidth: flickable.width
        ColumnLayout {
            id: layout
            width: 400
            x: (flickable.width - 400) / 2
            y: Math.max(0, (flickable.height - layout.height) / 2)
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
                WalletsDrawer.WalletButton {
                    Layout.fillWidth: true
                    id: wallet_button
                    onClicked: self.openWallet(wallet_button.wallet)
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
                WalletsDrawer.WalletButton {
                    Layout.fillWidth: true
                    id: wallet_button
                    onClicked: self.openWallet(wallet_button.wallet)
                }
            }
        }
    }
    header: Pane {
        background: null
        padding: 60
        bottomPadding: 20
        contentItem: ColumnLayout {
            Image {
                Layout.alignment: Qt.AlignCenter
                source: 'qrc:/svg2/blockstream_green.svg'
            }
        }
    }
    footer: Pane {
        background: null
        padding: 60
        topPadding: 20
        contentItem: ColumnLayout {
            WalletsDrawer.ListButton {
                Layout.alignment: Qt.AlignCenter
                Layout.maximumWidth: 400
                contentItem: RowLayout {
                    spacing: 14
                    Label {
                        Layout.alignment: Qt.AlignCenter
                        Layout.fillWidth: true
                        Layout.preferredWidth: 0
                        font.pixelSize: 14
                        font.weight: 500
                        text:  qsTrId('id_setup_a_new_wallet')
                        elide: Label.ElideRight
                    }
                    Image {
                        Layout.alignment: Qt.AlignCenter
                        source: 'qrc:/svg2/right.svg'
                    }
                }
                onClicked: self.createWallet()
            }
        }
    }
}
