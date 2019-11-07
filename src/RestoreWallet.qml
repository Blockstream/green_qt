import Blockstream.Green 0.1
import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.13
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.12

import './views'

Item {
    StackView {
        id: stack_view
        anchors.centerIn: parent
        clip: true
        implicitWidth: currentItem.implicitWidth
        implicitHeight: currentItem.implicitHeight

        initialItem: network_page
    }

    property Item network_page: NetworkPage {
        id: network_page
        accept.onTriggered: stack_view.push(mnemonic_page)
    }

    property Item mnemonic_page: MnemonicEditor {
        accept.text: qsTr('id_next')
        accept.onTriggered: stack_view.push(passwordProtected ? password_page : pin_page)
    }

    property Item password_page: WizardPage {
        TextField {
            id: password_field
            anchors.centerIn: parent
            echoMode: TextField.Password
            onAccepted: stack_view.push(pin_page)
        }
    }

    property Item pin_page: WizardPage {
        PinView {
            id: pin_view
            anchors.centerIn: parent
            onValidChanged: if (valid) stack_view.push(pin_verify_page)
        }
    }

    property Item pin_verify_page: WizardPage {
        PinView {
            anchors.centerIn: parent
            onPinChanged: {
                if (pin === pin_view.pin) stack_view.push(name_page)
                else clear()
            }
        }
    }

    property Item name_page: WizardPage {
        title: qsTr('id_done')

        TextField {
            id: name_field
            anchors.centerIn: parent
            onAccepted: {
                currentWallet = WalletManager.signup('', false, network_page.network, name_field.text, mnemonic_page.mnemonic, password_field.text, pin_view.pin);
            }
        }
    }
}
