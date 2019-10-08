import Blockstream.Green 0.1
import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.5
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.12
import './views'

FocusScope {
    enabled: wallet.online && !wallet.authenticating

    ColumnLayout {
        spacing: 16
        anchors.centerIn: parent
        width: parent.width

        opacity: wallet.authenticating ? 0.5 : 1

        FlatButton {
            visible: false
            text: "TEST"
            onClicked: wallet.test()
        }

        Label {
            font.capitalization: Font.AllUppercase
            font.family: dinpro.name
            font.pixelSize: 30
            text: wallet.name
            Layout.alignment: Qt.AlignHCenter
        }

        Label {
            font.capitalization: Font.AllUppercase
            text: qsTr('id_enter_pin')
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

        PinView {
            id: pin_view
            enabled: wallet.loginAttemptsRemaining > 0
            Layout.alignment: Qt.AlignHCenter

            onPinChanged: if (valid) {
                wallet.login(pin)
                wallet.reload()
            }
        }
    }

    Connections {
        target: wallet
        onAuthenticatingChanged: if (!authenticating) pin_view.clear()
    }

    BusyIndicator {
        anchors.centerIn: parent
        opacity: !wallet.online || wallet.authenticating ? 1 : 0
        Behavior on opacity {
            NumberAnimation { duration: 300 }
        }
    }

}
