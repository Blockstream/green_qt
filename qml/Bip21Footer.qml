import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Collapsible {
    readonly property Wallet wallet: stack_layout.currentItem?.wallet ?? null
    readonly property Context context: self.wallet?.context ?? null
    readonly property Account account: stack_layout.currentItem?.currentAccount ?? null
    readonly property bool compatible: {
        if (!self.account) return false
        const parts = WalletManager.openUrl.split(':')
        const bip21_prefix = self.account.network.data.bip21_prefix
        return bip21_prefix === (parts.length === 1 ? 'bitcoin' : parts[0])
    }
    id: self
    collapsed: !WalletManager.hasOpenUrl
    contentWidth: self.width
    contentHeight: pane.height - 20
    animationVelocity: 200
    Pane {
        id: pane
        leftPadding: 20
        rightPadding: 20
        topPadding: 20
        bottomPadding: 40
        x: 25
        width: self.width - 50
        background: Rectangle {
            color: '#00B45A'
            radius: 8
        }
        contentItem: RowLayout {
            spacing: 20
            ColumnLayout {
                Label {
                    color: '#FFF'
                    font.pixelSize: 16
                    font.weight: 500
                    opacity: 0.9
                    text: {
                        if (!self.wallet) return 'Select wallet to pay'
                        if (!self.context) return 'Login to pay'
                        if (!self.compatible) return 'Select compatible account to pay'
                        return 'Payment'
                    }
                }
                Label {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                    color: '#FFF'
                    elide: Label.ElideMiddle
                    font.pixelSize: 12
                    font.weight: 600
                    text: WalletManager.openUrl
                }
            }
            RegularButton {
                topPadding: 10
                bottomPadding: 10
                enabled: self.compatible
                text: 'Pay'
                visible: !!self.context
                onClicked: {
                    stack_layout.currentItem?.send(WalletManager.openUrl)
                    WalletManager.clearOpenUrl()
                }
            }
            RegularButton {
                topPadding: 10
                bottomPadding: 10
                text: qsTrId('id_cancel')
                visible: !!self.context
                onClicked: WalletManager.clearOpenUrl()
            }
            CloseButton {
                visible: !self.context
                onClicked: WalletManager.clearOpenUrl()
            }
        }
    }
}
