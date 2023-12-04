import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

WalletDrawer {
    required property Address address
    id: self
    contentItem: GStackView {
        id: stack_view
        initialItem: AddressDetailsPage {
            context: self.context
            address: self.address
            closeAction: Action {
                onTriggered: self.close()
            }
        }
    }
}
