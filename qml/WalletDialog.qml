import Blockstream.Green
import QtQuick
import QtQuick.Controls

AbstractDialog {
    id: self
    required property Wallet wallet
    Connections {
        target: self.wallet.session
        function onConnectedChanged(connected) {
            if (!connected) reject();
        }
    }
    Connections {
        target: self.wallet
        function onAuthenticationChanged(authentication) {
            if (authentication !== Wallet.Authenticated) reject();
        }
    }
}
