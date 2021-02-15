import Blockstream.Green 0.1
import Blockstream.Green.Core 0.1
import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.13
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.12

AbstractDialog {
    id: self
    required property string network

    RestoreController {
        id: controller
        network: NetworkManager.network(self.network)
        onFinished: pushLocation(`/${self.network}/${wallet.id}`)
        Component.onCompleted: {
            const proxy = Settings.useProxy ? Settings.proxyHost + ':' + Settings.proxyPort : ''
            const use_tor = Settings.useTor
            controller.wallet.connect(proxy, use_tor)
        }
    }

    Connections {
        target: controller.wallet
        function onLoginError(error) {
            if (error.includes('id_login_failed')) {
                footer_buttons_row.ToolTip.show(qsTrId('id_login_failed'), 2000);
            } else if (error.includes('bip39_mnemonic_to_seed')) {
                footer_buttons_row.ToolTip.show(qsTrId('id_invalid_mnemonic'), 2000);
            } else if (error.includes('reconnect required')) {
                footer_buttons_row.ToolTip.show(qsTrId('id_unable_to_contact_the_green'), 2000);
            } else {
                footer_buttons_row.ToolTip.show(error, 2000);
            }
        }
        function onAuthenticationChanged(authentication) {
            if (controller.wallet.authentication === Wallet.Authenticated) {
                stack_view.push(pin_page)
                pin_page.forceActiveFocus()
            }
        }
    }

    contentItem: StackView {
        id: stack_view
        implicitWidth: currentItem.implicitWidth
        implicitHeight: currentItem.implicitHeight
        initialItem: mnemonic_page
    }

    footer: Pane {
        padding: 0
        background: Item {
        }
        RowLayout {
            id: footer_buttons_row
            anchors.fill: parent
            spacing: 8
            ProgressBar {
                Layout.maximumWidth: 64
                indeterminate: true
                opacity: controller.wallet && controller.wallet.authentication === Wallet.Authenticating ? 0.5 : 0
                visible: opacity > 0
                Behavior on opacity {
                    SmoothedAnimation {
                        duration: 500
                        velocity: -1
                    }
                }
            }
            Item {
                Layout.fillWidth: true
                height: 1
            }
            Repeater {
                model: stack_view.currentItem.actions
                Button {
                    focus: modelData.focus || false
                    action: modelData
                    flat: true
                }
            }
        }
    }

    icon: icons[controller.network.id]
    title: stack_view.currentItem.title
    toolbar: stack_view.currentItem.toolbar || null

    property Item mnemonic_page: MnemonicEditor {
        id: mnemonicEditor
        title: qsTrId('Insert your green mnemonic')
        actions: [
            Action {
                property bool focus: mnemonic_page.valid
                text: qsTrId('id_clear')
                onTriggered: mnemonicEditor.controller.clear();
            },
            Action {
                property bool focus: mnemonic_page.valid
                text: qsTrId('id_continue')
                enabled: mnemonic_page.valid && controller.wallet.authentication === Wallet.Unauthenticated
                onTriggered: {
                    if (mnemonic_page.password) {
                        stack_view.push(password_page)
                    } else {
                        controller.wallet.login(mnemonic_page.mnemonic)
                    }
                }
            }
        ]
    }

    property Item password_page: WizardPage {
        title: qsTrId('id_please_provide_your_passphrase')
        actions: [
            Action {
                id: passphrase_next_action
                text: qsTrId('id_continue')
                enabled: controller.wallet && controller.wallet.authentication === Wallet.Unauthenticated && password_field.text.trim().length > 0
                onTriggered: controller.wallet.login(mnemonic_page.mnemonic, password_field.text.trim())
            }
        ]
        TextField {
            id: password_field
            anchors.centerIn: parent
            implicitWidth: 400
            echoMode: TextField.Password
            onAccepted: passphrase_next_action.trigger()
            placeholderText: qsTrId('id_encryption_passphrase')
        }
    }

    property Item pin_page: WizardPage {
        title: qsTrId('id_set_a_new_pin')
        PinView {
            id: pin_view
            anchors.centerIn: parent
            onValidChanged: if (valid) stack_view.push(pin_verify_page)
        }
    }

    property Item pin_verify_page: WizardPage {
        title: qsTrId('id_verify_your_pin')
        PinView {
            anchors.centerIn: parent
            onPinChanged: {
                if (pin !== pin_view.pin) {
                    clear();
                    ToolTip.show(qsTrId('id_pins_do_not_match_please_try'), 1000);
                } else {
                    controller.wallet.setPin(pin_view.pin);
                    stack_view.push(name_page);
                }
            }
        }
    }

    property Item name_page: ColumnLayout {
        property string title: qsTrId('id_set_wallet_name')
        property list<Action> actions: [
            Action {
                text: qsTrId('id_restore')
                onTriggered: {
                    controller.name = name_field.text.trim();
                    controller.restore()
                }
            }
        ]

        TextField {
            id: name_field
            Layout.fillWidth: true
            Layout.minimumWidth: 300
            font.pixelSize: 16
            placeholderText: controller.defaultName
        }
    }
}
