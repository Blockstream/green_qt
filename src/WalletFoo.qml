import Blockstream.Green 0.1
import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.13
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.12

StackLayout {
    id: root

    property Wallet wallet

    property string title: `${wallet.name}`

//    Connections {
//        target: wallet
//        onLoggedChanged: {
//            if (wallet.logged) {
//                root.replace(wallet_view)
//                //sidebar.push(xpto)
//            }
//        }
//    }

    currentIndex: wallet.logged ? 1 : 0

    LoginView { }

    Loader {
        active: wallet.logged
        sourceComponent: WalletView { }
    }


}
