import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "analytics.js" as AnalyticsJS
import "util.js" as UtilJS

WalletDrawer {
    required property Asset asset
    id: self
    preferredContentWidth: stack_view.currentItem.implicitWidth

    contentItem: GStackView {
        id: stack_view
        focus: true
        initialItem: CreateAccountPage {
            id: page
            context: self.context
            asset: self.asset
            editableAsset: true
            onCloseClicked: self.close()
            onCreated: (account) => {
                const network = account.network
                const id = network.liquid ? network.policyAsset : 'btc'
                const asset = self.context.getOrCreateAsset(id)
                stack_view.replace(null, account_asset_page, { account, asset }, StackView.PushTransition)
            }
        }
    }

    Component {
        id: account_asset_page
        AccountAssetPage {
            id: page
            context: self.context
            onCloseClicked: self.close()
        }
    }
}
