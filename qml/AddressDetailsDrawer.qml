import Blockstream.Green
import Blockstream.Green.Core
import QtQuick

WalletDrawer {
    required property Address address
    id: self
    contentItem: GStackView {
        id: stack_view
        initialItem: AddressDetailsPage {
            context: self.context
            address: self.address
            onCloseClicked: self.close()
        }
    }
}
