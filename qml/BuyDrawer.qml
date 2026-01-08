import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

WalletDrawer {
    Component.onCompleted: {
        const accounts = (self.context?.accounts ?? []).filter(account => !account.hidden && !account.network.liquid);
        for (const account of accounts) {
            if (account.type === 'p2wpkh') {
                stack_view.push(null, buy_page, { account })
                return
            }
        }
        for (const account of accounts) {
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
            asset: self.context.getOrCreateAsset('btc')
            context: self.context
            editableAsset: false
            onCloseClicked: self.close()
            onCreated: (account) => stack_view.replace(null, buy_page, { account }, StackView.PushTransition )
        }
    }
}
