import Blockstream.Green
import Blockstream.Green.Core
import QtQuick

WalletDrawer {
    required property ContextTransaction transaction
    id: self
    contentItem: GStackView {
        id: stack_view
        Component.onCompleted: {
            if (self.transaction instanceof LightningTransaction) {
                stack_view.push(null, lightning_transaction_page)
            } else {
                stack_view.push(null, transaction_view)
            }
        }
    }

    Component {
        id: transaction_view
        TransactionView {
            transaction: self.transaction
            onCloseClicked: self.close()
        }
    }

    Component {
        id: lightning_transaction_page
        LightningTransactionPage {
            context: self.context
            transaction: self.transaction
            onCloseClicked: self.close()
        }
    }
}
