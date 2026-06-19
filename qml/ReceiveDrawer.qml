import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls

import 'util.js' as UtilJS

WalletDrawer {
    readonly property list<Account> accounts: UtilJS.accounts(self.context)
    readonly property list<Asset> assets: UtilJS.assets(self.context)
    readonly property bool lockAssetAndAccount: {
        if (!self.context.watchonly) return false
        return self.accounts.length === 1 && self.assets.length === 1
    }
    id: self
    preferredContentWidth: stack_view.currentItem.implicitWidth
    minimumContentWidth: 400
    contentItem: GStackView {
        id: stack_view
        title: qsTrId('id_receive')
        initialItem: {
            if (self.lockAssetAndAccount) {
                return receive_page
            }
            return select_account_asset_page
        }
    }
    Component {
        id: select_account_asset_page
        ReceiveAccountAssetSelector {
            context: self.context
            onCloseClicked: self.close()
            onLightningSelected: {
                stack_view.replace(null, lightning_receive_page, {}, StackView.PushTransition)
            }
            onSelected: (account, asset) => {
                stack_view.replace(null, receive_page, { account, asset }, StackView.PushTransition)
            }
        }
    }
    Component {
        id: receive_page
        ReceivePage {
            account: self.accounts[0] ?? null
            asset: self.assets[0] ?? null
            context: self.context
            lockAssetAndAccount: self.lockAssetAndAccount
            title: qsTrId('id_review')
            onCloseClicked: self.close()
        }
    }
    Component {
        id: lightning_receive_page
        LightningReceivePage {
            context: self.context
            onCloseClicked: self.close()
        }
    }
}
