import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import QtQuick.Window
import Qt5Compat.GraphicalEffects

import "analytics.js" as AnalyticsJS

MainPage {
    signal openWallet(Wallet wallet)
    signal createWallet

    readonly property WalletView currentWalletView: null
    readonly property bool active: {
        if (window.navigation.param.view === 'wallets') return true
        const wallet = WalletManager.wallet(window.navigation.param.wallet)
        if (wallet) return true
        return false
    }

    id: self
    header: MainPageHeader {
        background: Rectangle {
            color: constants.c700
            opacity: wallet_list_view.contentY > 0 ? 1 : 0
            Behavior on opacity {
                SmoothedAnimation {
                    velocity: 4
                }
            }

            FastBlur {
                anchors.fill: parent
                cached: true
                opacity: 0.55

                radius: 128
                source: ShaderEffectSource {
                    sourceItem: self.contentItem
                    sourceRect {
                        x: -self.contentItem.x
                        y: -self.contentItem.y
                        width: self.header.width
                        height: self.header.height
                    }
                }
            }
            Rectangle {
                width: parent.width
                height: 1
                y: parent.height - 1
                color: constants.c900
            }
        }

        contentItem: RowLayout {
            spacing: 16
            Label {
                text: self.title
                font.pixelSize: 24
                font.styleName: 'Medium'
                Layout.fillWidth: true
            }
        }
    }
    footer: StatusBar {
        RegularButton {
            text: qsTrId('id_setup_a_new_wallet')
            onClicked: self.createWallet()
        }
    }

    contentItem: GPane {
        background: Item {
            Label {
                anchors.centerIn: parent
                visible: wallet_list_view.count === 0
                text: qsTrId('id_looks_like_you_havent_used_a');
            }
        }
        contentItem: TListView {
            id: wallet_list_view
            currentIndex: -1
            model: WalletListModel {
            }
            delegate: WalletListDelegate {
                width: ListView.view.contentWidth
                onClicked: self.openWallet(wallet)
            }
        }
    }
}
