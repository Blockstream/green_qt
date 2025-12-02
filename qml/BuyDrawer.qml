import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

WalletDrawer {
    Component.onCompleted: {
        for (const account of self.context?.accounts ?? []) {
            if (account.hidden) continue
            if (account.network.liquid) continue
            stack_view.push(null, buy_page, { account })
            return
        }
        stack_view.push(null, create_account_page)
    }

    id: self
    minimumContentWidth: 450
    contentItem: GStackView {
        id: stack_view
    }
    Component {
        id: buy_page
        BuyPage {
            context: self.context
            onCloseClicked: self.close()
            onShowTransactions: self.close()
        }
    }
    Component {
        id: create_account_page
        CreateAccountPage {
            rightItem: CloseButton {
                onClicked: self.close()
            }
            asset: self.context.getOrCreateAsset('btc')
            context: self.context
            editableAsset: false
            onCreated: (account) => stack_view.replace(null, buy_page, { account }, StackView.PushTransition )
        }
    }
}
