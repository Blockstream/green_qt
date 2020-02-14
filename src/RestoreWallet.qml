import Blockstream.Green 0.1
import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.13
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.12

import './views'

Page {
    property Wallet wallet

    property Action cancel: Action {}

    signal finished()

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

    background: Item {}

    footer: Item {
        height: 64

        BusyIndicator {
            visible: running
            running: wallet.authentication === Wallet.Authenticating
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.margins: 16
            scale: 0.5
        }

        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.margins: 16
            Repeater {
                model: stack_view.currentItem.actions
                Button {
                    action: modelData
                    flat: true
                    Layout.rightMargin: 16
                    Layout.bottomMargin: 16
                    Layout.topMargin: 16
                    Layout.minimumWidth: 128
                }
            }
        }
    }

    header: Item {
        height: 64

        Row {
            visible: !!network_page.network
            anchors.margins: 16
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: 16
            Image {
                anchors.verticalCenter: parent.verticalCenter
                source: network_page.network ? icons[network_page.network.id] : ''
                sourceSize.height: 32
                sourceSize.width: 32
            }
            Label {
                anchors.verticalCenter: parent.verticalCenter
                font.pixelSize: 24
                text: network_page.network ? network_page.network.name : ''
            }
        }

        Label {
            anchors.centerIn: parent
            font.pixelSize: 24
            text: qsTrId('Restore Wallet') + ' - ' + stack_view.currentItem.title
        }

        Row {
            anchors.margins: 16
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            ToolButton {
                onClicked: settings_drawer.open()
                icon.source: 'assets/svg/settings.svg'
            }

            ToolButton {
                action: cancel
                icon.source: 'assets/svg/cancel.svg'
                icon.width: 16
                icon.height: 16
            }
        }
    }

    property Item network_page: NetworkPage {
        property string title: qsTrId('id_choose_your_network')

        id: network_page
        onNetworkChanged: {
            if (network) {
                wallet.network = network_page.network;
                wallet.connect();
                stack_view.push(mnemonic_page);
            }
        }
    }

    property Item mnemonic_page: MnemonicEditor {
        title: qsTrId('Insert your green mnemonic')
        actions: [
            Action {
                text: qsTrId('id_continue')
                enabled: mnemonic_page.complete && wallet.authentication === Wallet.Unauthenticated
                onTriggered: {
                    if (mnemonic_page.passwordProtected) {
                        stack_view.push(password_page)
                    } else {
                        wallet.login(mnemonic_page.mnemonic)
                    }
                }
            }
        ]
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
        title: qsTrId('Set a new PIN')
        PinView {
            id: pin_view
            anchors.centerIn: parent
            onValidChanged: if (valid) stack_view.push(pin_verify_page)
        }
    }

    property Item pin_verify_page: WizardPage {
        title: qsTrId('Confirm PIN')
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

    property Item name_page: ColumnLayout {
        property string title: qsTrId('Set wallet name')
        property list<Action> actions: [
            Action {
                enabled: name_field.text.trim().length > 0
                text: qsTr('id_create')
                onTriggered: {
                    wallet.name = name_field.text;
                    finished()
                }
            }
        ]

        TextField {
            id: name_field
            Layout.minimumWidth: 300
            font.pixelSize: 16
            placeholderText: qsTrId('My %1 Wallet').arg(network_page.network ? network_page.network.name : '')
        }
    }
}
