import Blockstream.Green
import QtQuick
import QtQuick.Controls

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
