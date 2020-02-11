import Blockstream.Green 0.1
import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.5
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.12
import './views'

ColumnLayout {
    spacing: 16
    anchors.horizontalCenter: parent.horizontalCenter

    function login() {
        if (pin_view.valid && wallet.connection === Wallet.Connected) {
            wallet.loginWithPin(pin_view.pin)
        }
    }

    Label {
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap

        text: switch (wallet.loginAttemptsRemaining) {
            case 0: return qsTr('id_no_attempts_remaining')
            case 1: return qsTr('id_last_attempt_if_failed_you_will')
            case 2: return qsTr('id_attempts_remaining_d').arg(wallet.loginAttemptsRemaining)
            default: return qsTr('id_enter_pin')
        }
        Layout.alignment: Qt.AlignHCenter
        Layout.fillWidth: true
    }

    PinView {
        id: pin_view
        enabled: wallet.loginAttemptsRemaining > 0

        onPinChanged: login()
    }

    height: wallet.authentication === Wallet.Unauthenticated && !pin_view.valid ? implicitHeight : 1
    width: pin_view.implicitWidth

    Behavior on height {
        NumberAnimation {
            easing.type: Easing.OutCubic
        }
    }
}
