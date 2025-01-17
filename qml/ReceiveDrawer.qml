import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

WalletDrawer {
    required property Account account
    required property Asset asset

    onClosed: self.destroy()

    id: self
    preferredContentWidth: stack_view.currentItem.implicitWidth
    minimumContentWidth: 400
    contentItem: GStackView {
        id: stack_view
        initialItem: ReceivePage {
            account: self.account
            asset: self.asset
            context: self.context
            onClosed: self.close()
        }
    }
}
