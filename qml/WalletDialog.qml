import Blockstream.Green
import QtQuick

AbstractDialog {
    required property Context context
    readonly property Wallet wallet: self.context.wallet
    id: self
    Connections {
        target: self.context
        function onAutoLogout() {
            self.close()
        }
    }
}
