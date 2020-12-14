import Blockstream.Green 0.1
import QtQuick 2.14
import QtQuick.Controls 2.14

AbstractDialog {
    Connections {
        target: wallet
        function onConnectionChanged(connection) {
            if (wallet.connection === Wallet.Disconnected) {
                reject();
            }
        }
    }
}
