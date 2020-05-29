import Blockstream.Green 0.1
import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Layouts 1.13

SidebarItem {
    title: qsTrId('id_wallets')

    Repeater {
        model: WalletManager.wallets

        ItemDelegate {
            property Wallet wallet: modelData

            leftPadding: 16
            icon.color: 'transparent'
            icon.source: icons[wallet.network.id]
            icon.width: 32
            icon.height: 32
            text: wallet.name
            width: parent.width

            onClicked: currentWallet = modelData

            highlighted: modelData === currentWallet
        }
    }
}
