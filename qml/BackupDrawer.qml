import Blockstream.Green
import Blockstream.Green.Core
import QtQuick

WalletDrawer {
    id: self
    contentItem: GStackView {
        id: stack_view
        initialItem: BackupPage {
            context: self.context
            onCloseClicked: self.close()
            onCompleted: self.close()
        }
    }
}
