import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "util.js" as UtilJS

StackViewPage {
    signal newWallet()
    signal restoreWallet()
    StackView.onActivated: Analytics.recordEvent('wallet_add')
    id: self
    footer: null
    padding: 60
    MultiImage {
        Layout.alignment: Qt.AlignCenter
        //Layout.bottomMargin: -70
        foreground: 'qrc:/svg2/take_control2.svg'
        clip: false
        width: 300
        height: 182
    }
    Label {
        Layout.alignment: Qt.AlignCenter
        color: '#FFF'
        font.pixelSize: 35
        font.weight: 656
        horizontalAlignment: Label.AlignHCenter
        text: qsTrId('id_take_control_your_keys_your').replace(':', ':\n')
    }
    Label {
        Layout.alignment: Qt.AlignCenter
        Layout.maximumWidth: 230
        Layout.topMargin: 10
        color: '#FFF'
        font.pixelSize: 14
        font.weight: 400
        horizontalAlignment: Label.AlignHCenter
        opacity: 0.6
        text: qsTrId('id_your_keys_secure_your_coins_on')
        wrapMode: Label.WordWrap
    }
    PrimaryButton {
        Layout.alignment: Qt.AlignCenter
        Layout.minimumWidth: 325
        Layout.topMargin: 20
        text: qsTrId('id_new_wallet')
        onClicked: self.newWallet()
    }
    RegularButton {
        Layout.alignment: Qt.AlignCenter
        Layout.minimumWidth: 325
        Layout.topMargin: 10
        text: qsTrId('id_restore_wallet')
        onClicked: self.restoreWallet()
    }
}
