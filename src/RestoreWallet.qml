import Blockstream.Green 0.1
import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.13
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.12

import './views'

Page {
    property Wallet wallet

    property Action cancel: Action {
        text: qsTr('id_cancel')
    }
    property Action accept: Action {
    }

    Connections {
        target: wallet
        onAuthenticationChanged: {
            // TODO show error message
            if (wallet.authentication === Wallet.Authenticated) {
                stack_view.push(pin_page)
            }
        }
    }

    StackView {
        id: stack_view
        anchors.centerIn: parent
        clip: true
        implicitWidth: currentItem.implicitWidth
        implicitHeight: currentItem.implicitHeight

        initialItem: network_page
    }

    footer: RowLayout {
        Button {
            Layout.alignment: Qt.AlignRight
            flat: true
            action: cancel
        }
    }

    property Item network_page: NetworkPage {
        id: network_page
        accept.onTriggered: {
            wallet.network = network_page.network;
            wallet.connect();
            stack_view.push(mnemonic_page)
        }
    }

    property Item mnemonic_page: MnemonicEditor {
        accept.text: qsTr('id_next')
        accept.enabled: wallet.authentication === Wallet.Unauthenticated
        accept.onTriggered: {
            if (passwordProtected) {
                stack_view.push(password_page)
            } else {
                wallet.login(mnemonic_page.mnemonic)
            }
        }
    }

    property Item password_page: WizardPage {
        TextField {
            id: password_field
            anchors.centerIn: parent
            echoMode: TextField.Password
            onAccepted: wallet.login(mnemonic_page.mnemonic, password_field.text)
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
                if (pin !== pin_view.pin) {
                    clear();
                } else {
                    wallet.setPin(mnemonic_page.mnemonic, pin_view.pin);
                    stack_view.push(name_page);
                }
            }
        }
    }

    property Item name_page: WizardPage {
        title: qsTr('id_done')

        TextField {
            id: name_field
            anchors.centerIn: parent
            onAccepted: {
                // TODO should validate name
                wallet.name = name_field.text;
                accept.trigger()
            }
        }
    }
}
