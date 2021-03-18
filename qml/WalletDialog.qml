import Blockstream.Green 0.1
import QtQuick 2.14
import QtQuick.Controls 2.14

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
