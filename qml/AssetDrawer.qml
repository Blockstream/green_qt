import Blockstream.Green
import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts

import "util.js" as UtilJS

WalletDrawer {
    signal accountClicked(Asset asset, Account account)
    required property Asset asset

    Component.onCompleted: {
        let accounts = self.context?.accounts ?? []
        accounts = accounts.filter(account => account.network.key === self.asset.networkKey)
        accounts = accounts.filter(account => !account.hidden)
        if (accounts.length === 0) {
            stack_view.push(null, create_account_page)
        } else if (accounts.length === 1) {
            stack_view.push(null, account_asset_page, { account: accounts[0] })
        } else {
            stack_view.push(null, asset_details_page)
        }
    }

    id: self
    contentItem: GStackView {
        id: stack_view
        focus: true
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
            asset: self.asset
            context: self.context
            onCloseClicked: self.close()
        }
    }

    Component {
        id: create_account_page
        CreateAccountPage {
            asset: self.asset
            context: self.context
            editableAsset: false
            onCloseClicked: self.close()
            onCreated: (account) => {
                stack_view.replace(null, account_asset_page, { account }, StackView.PushTransition)
            }
        }
    }
}
