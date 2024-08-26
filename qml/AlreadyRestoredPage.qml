import Blockstream.Green
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

StackViewPage {
    signal openWallet(Wallet wallet)
    signal cancel
    required property Wallet wallet

    id: self
    footer: null
    padding: 60
    Label {
        Layout.alignment: Qt.AlignCenter
        Layout.topMargin: 20
        color: '#FFF'
        font.pixelSize: 35
        font.weight: 656
        horizontalAlignment: Label.AlignHCenter
        text: self.wallet.name
    }
    Label {
        Layout.alignment: Qt.AlignCenter
        color: '#FFF'
        font.pixelSize: 22
        font.weight: 400
        horizontalAlignment: Label.AlignHCenter
        text: qsTrId('id_wallet_already_restored')
    }
    PrimaryButton {
        Layout.alignment: Qt.AlignCenter
        Layout.minimumWidth: 325
        Layout.topMargin: 80
        text: 'Switch to wallet'
        onClicked: self.openWallet(self.wallet)
    }
    RegularButton {
        Layout.alignment: Qt.AlignCenter
        Layout.minimumWidth: 325
        Layout.topMargin: 10
        text: qsTrId('id_cancel')
        onClicked: self.cancel()
    }
}
