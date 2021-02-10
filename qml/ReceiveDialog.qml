import Blockstream.Green 0.1
import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Layouts 1.12

WalletDialog {
    title: qsTrId('id_receive')
    icon: 'qrc:/svg/receive.svg'
    onClosed: destroy()
    ReceiveView {
        account: currentAccount
    }
}
