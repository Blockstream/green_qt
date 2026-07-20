import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls

WalletDrawer {
    property bool amp2: false
    required property Asset asset
    id: self
    preferredContentWidth: stack_view.currentItem.implicitWidth

    contentItem: GStackView {
        id: stack_view
        focus: true
        initialItem: self.amp2 ? create_amp2_account_page : create_account_page
    }

    Component {
        id: create_account_page
        CreateAccountPage {
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
        id: create_amp2_account_page
        CreateAmp2AccountPage {
            context: self.context
            onCloseClicked: self.close()
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
