import Blockstream.Green 0.1
import Blockstream.Green.Core 0.1
import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.13
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.12

AbstractDialog {
    required property Network network

    id: self

    RestoreController {
        id: controller
        network: self.network
        mnemonic: mnemonic_page.mnemonic
        password: password_field.text
        pin: pin_view.pin.value

    }

    Connections {
        target: controller.wallet
        function onActivityCreated(activity) {
            if (activity instanceof CheckRestoreActivity) {
                const view = check_view.createObject(activities_row, { activity })
                activity.finished.connect(() => {
                    view.destroy()
                })
            } else if (activity instanceof AcceptRestoreActivity) {
                const view = accept_view.createObject(activities_row, { activity })
                activity.finished.connect(() => {
                    view.destroy()
                    pushLocation(`/${self.network.id}/${controller.wallet.id}`)
                })
            }
        }
    }

    Connections {
        target: controller.wallet ? controller.wallet.session : null
        function onActivityCreated(activity) {
            if (activity instanceof SessionTorCircuitActivity) {
                session_tor_cirtcuit_view.createObject(activities_row, { activity })
            } else if (activity instanceof SessionConnectActivity) {
                session_connect_view.createObject(activities_row, { activity })
            }
        }
    }

    Connections {
        target: controller.wallet
        function onLoginError(error) {
            if (error.includes('id_login_failed')) {
                self.footer.ToolTip.show(qsTrId('id_login_failed'), 2000);
            } else if (error.includes('bip39_mnemonic_to_seed')) {
                self.footer.ToolTip.show(qsTrId('id_invalid_mnemonic'), 2000);
            } else if (error.includes('reconnect required')) {
                self.footer.ToolTip.show(qsTrId('id_unable_to_contact_the_green'), 2000);
            } else {
                self.footer.ToolTip.show(error, 2000);
            }
        }
        function onAuthenticatedChanged() {
            if (controller.wallet.authenticated) {
                stack_view.push(pin_page)
            }
        }
    }

    closePolicy: Popup.NoAutoClose

    contentItem: StackView {
        id: stack_view
        onCurrentItemChanged: currentItem.forceActiveFocus()
        implicitWidth: currentItem.implicitWidth
        implicitHeight: currentItem.implicitHeight
        initialItem: mnemonic_page
    }

    footer: DialogFooter {
        Pane {
            Layout.minimumHeight: 48
            background: null
            padding: 0
            contentItem: RowLayout {
                id: activities_row
            }
        }
        HSpacer {}
        Repeater {
            model: stack_view.currentItem.actions
            GButton {
                focus: modelData.focus || false
                action: modelData
                large: true
            }
        }
    }

    icon: icons[controller.network.id]
    title: stack_view.currentItem.title
    toolbar: stack_view.currentItem.toolbar || null

    property Item mnemonic_page: MnemonicEditor {
        id: mnemonicEditor
        enabled: !controller.active
        title: qsTrId('Insert your green mnemonic')
        actions: [
            Action {
                property bool focus: mnemonic_page.valid
                enabled: !controller.active
                text: qsTrId('id_clear')
                onTriggered: mnemonicEditor.controller.clear();
            },
            Action {
                property bool focus: mnemonic_page.valid
                text: qsTrId('id_continue')
                enabled: !controller.active && controller.valid || (mnemonic_page.valid && mnemonic_page.password)
                onTriggered: {
                    if (mnemonic_page.password) {
                        stack_view.push(password_page)
                    } else {
                        controller.active = true
                        // controller.wallet.login()
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
                enabled: !controller.active && controller.valid
                onTriggered: controller.active = true
            }
        ]
        TextField {
            id: password_field
            anchors.centerIn: parent
            implicitWidth: 400
            echoMode: TextField.Password
            onAccepted: passphrase_next_action.trigger()
            enabled: !controller.active
            placeholderText: qsTrId('id_encryption_passphrase')
        }
    }

    property Item pin_page: WizardPage {
        title: qsTrId('id_set_a_new_pin')
        PinView {
            id: pin_view
            anchors.centerIn: parent
            onPinChanged: if (pin.valid) stack_view.push(pin_verify_page)
        }
    }

    property Item pin_verify_page: WizardPage {
        title: qsTrId('id_verify_your_pin')
        PinView {
            anchors.centerIn: parent
            onPinChanged: {
                if (!pin.valid) return
                if (pin.value !== pin_view.pin.value) {
                    clear();
                    ToolTip.show(qsTrId('id_pins_do_not_match_please_try'), 1000);
                } else {
                    onTriggered: controller.accept()
                }
            }
        }
    }

    Component {
        id: check_view
        RowLayout {
            required property CheckRestoreActivity activity
            id: self
            BusyIndicator {
                Layout.preferredHeight: 32
                Layout.alignment: Qt.AlignCenter
            }
            Label {
                Layout.alignment: Qt.AlignCenter
                text: 'Checking'
            }
        }
    }

    Component {
        id: accept_view
        RowLayout {
            required property AcceptRestoreActivity activity
            id: self
            BusyIndicator {
                Layout.preferredHeight: 32
                Layout.alignment: Qt.AlignCenter
            }
            Label {
                Layout.alignment: Qt.AlignCenter
                text: 'Restoring'
            }
        }
    }
}
