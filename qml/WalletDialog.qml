import Blockstream.Green
import QtQuick
import QtQuick.Controls

AbstractDialog {
    id: self
    property Wallet wallet
    readonly property Context context: self.wallet?.context ?? null

    Connections {
        target: self.wallet
        function onContextChanged () {
            self.destroy()
        }
    }
}
