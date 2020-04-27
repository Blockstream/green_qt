import Blockstream.Green 0.1
import QtQuick 2.14
import QtQuick.Controls 2.14

AbstractDialog {
    Connections {
        target: wallet
        onConnectionChanged: {
            if (connection === Wallet.Disconnected) {
                reject();
            }
        }
    }
}
