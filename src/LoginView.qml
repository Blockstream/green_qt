import Blockstream.Green 0.1
import QtQuick 2.12
import QtQuick.Controls 2.5
import './views'

Column {
    signal login(string pin)

    spacing: 16

    Label {
        opacity: wallet.authentication === Wallet.Unauthenticated ? 1 : 0
        anchors.horizontalCenter: parent.horizontalCenter
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        text: switch (wallet.loginAttemptsRemaining) {
            case 0: return qsTrId('id_no_attempts_remaining')
            case 1: return qsTrId('id_last_attempt_if_failed_you_will')
            case 2: return qsTrId('id_attempts_remaining_d').arg(wallet.loginAttemptsRemaining)
            default: return qsTrId('id_enter_pin')
        }
        Behavior on opacity { NumberAnimation {} }
    }

    PinView {
        id: pin_view
        anchors.horizontalCenter: parent.horizontalCenter
        onPinChanged: {
            if (valid) {
                login(pin);
                clear();
            }
        }
    }
}
