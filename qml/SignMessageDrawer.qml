import Blockstream.Green
import QtQuick
import QtQuick.Controls

WalletDrawer {
    required property Address address
    onClosed: destroy()
    id: self
    contentItem: GStackView {
        initialItem: SignMessagePage {
            rightItem: CloseButton {
                onClicked: self.close()
            }
            context: self.context
            address: self.address
        }
    }
}
