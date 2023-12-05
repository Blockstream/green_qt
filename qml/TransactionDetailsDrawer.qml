import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls

WalletDrawer {
    required property Transaction transaction
    id: self
    minimumContentWidth: 550
    contentItem: GStackView {
        initialItem: TransactionView { // DetailsPage {
            // context: self.context
            transaction: self.transaction
            closeAction: Action {
                onTriggered: self.close()
            }
        }
    }
}
