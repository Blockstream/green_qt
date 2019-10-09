import Blockstream.Green 0.1
import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.5
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.12
import './views'

Column {
    spacing: 16

    opacity: wallet.status & Wallet.Authenticating ? 0.5 : 1

    function login() {
        console.log('login: ', wallet.status, pin_view.valid)

        if (pin_view.valid && wallet.status === Wallet.Connected) {
            wallet.login(pin_view.pin)
        }

        if (wallet.status === Wallet.Ready) {
            wallet_stack_view.push(wallet_view)
        }
    }

    Connections {
        target: wallet
        onStatusChanged: login()
    }

    FlatButton {
        visible: false
        text: "TEST"
        onClicked: wallet.test()
    }

    Label {
        visible: false
        font.capitalization: Font.AllUppercase
        font.family: dinpro.name
        font.pixelSize: 30
        text: wallet.name
        Layout.alignment: Qt.AlignHCenter
    }

    Label {
        font.capitalization: Font.AllUppercase
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap

        visible: wallet.loginAttemptsRemaining < 3
        text: switch (wallet.loginAttemptsRemaining) {
            case 0: return qsTr('id_no_attempts_remaining')
            case 1: return qsTr('id_last_attempt_if_failed_you_will')
            default: return qsTr('id_attempts_remaining_d').arg(wallet.loginAttemptsRemaining)
        }
        Layout.alignment: Qt.AlignHCenter
        Layout.fillWidth: true
    }

    ColumnLayout {
        clip: true
        anchors.horizontalCenter: parent.horizontalCenter

        Label {
            font.capitalization: Font.AllUppercase
            text: qsTr('id_enter_pin')
            Layout.alignment: Qt.AlignHCenter
        }

        PinView {
            id: pin_view
            enabled: wallet.loginAttemptsRemaining > 0

            onPinChanged: login()
        }

        height: wallet.status & Wallet.Unauthenticated && !pin_view.valid ? implicitHeight : 1
        width: pin_view.implicitWidth

        Behavior on height {
            NumberAnimation {
                easing.type: Easing.OutCubic
            }
        }
    }
    Connections {
        target: wallet
        onStatusChanged: if (status !== 'authenticating') pin_view.clear()
    }
}
