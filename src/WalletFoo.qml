import Blockstream.Green 0.1
import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.13
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.12

FocusScope {
    property Wallet wallet

    StackLayout {
        currentIndex: wallet.logged ? 1 : 0
        anchors.fill: parent

        LoginView {
            focus: !wallet.logged
        }

        Loader {
            active: wallet.logged
            focus: wallet.logged
            sourceComponent: WalletView { }
        }
    }
}
