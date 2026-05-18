import Blockstream.Green
import Blockstream.Green.Core
import QtQuick

WalletDrawer {
    required property AccountTransaction transaction
    id: self
    contentItem: GStackView {
        initialItem: TransactionView {
            transaction: self.transaction
            onCloseClicked: self.close()
        }
    }
}
