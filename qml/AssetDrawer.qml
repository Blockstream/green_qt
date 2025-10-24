import Blockstream.Green
import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts

import "util.js" as UtilJS

WalletDrawer {
    signal accountClicked(Asset asset, Account account)
    required property Asset asset
    readonly property Account defaultAccount: {
        const accounts = []
        for (let i = 0; i < self.context.accounts.length; i++) {
            const account = self.context.accounts[i]
            if (account.hidden) continue
            const satoshi = account.json.satoshi[self.asset.id]
            if (satoshi) accounts.push(account)
        }
        return accounts.length === 1 ? accounts[0] : null
    }
    id: self
    contentItem: GStackView {
        id: stack_view
        initialItem: self.defaultAccount ? account_asset_page : asset_details_page
    }

    Component {
        id: asset_details_page
        AssetDetailsPage {
            context: self.context
            asset: self.asset
            onCloseClicked: self.close()
            onAccountClicked: (account) => {
                stack_view.push(account_asset_page, { account })
            }
        }
    }

    Component {
        id: account_asset_page
        AccountAssetPage {
            id: page
            account: self.defaultAccount
            asset: self.asset
            context: self.context
            onCloseClicked: self.close()
            onReceiveClicked: stack_view.push(receive_page, { account: page.account })
            onSendClicked: stack_view.push(send_page, { account: page.account })
            onTransactionClicked: (transaction) => {
                stack_view.push(transaction_details_page, { transaction })
            }
        }
    }

    Component {
        id: send_page
        SendPage {
            context: self.context
            asset: self.asset
            readonly: true
            onCloseClicked: self.close()
        }
    }

    Component {
        id: receive_page
        ReceivePage {
            context: self.context
            asset: self.asset
            readonly: true
            onCloseClicked: self.close()
        }
    }

    Component {
        id: transaction_details_page
        TransactionView {
            onCloseClicked: self.close()
        }
    }
}
