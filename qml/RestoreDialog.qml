import Blockstream.Green 0.1
import Blockstream.Green.Core 0.1
import QtQuick 2.15
import QtQml 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQml.Models 2.0

AbstractDialog {
    id: self
    title: qsTrId('id_restore_green_wallet')
    width: 850
    height: 500
    closePolicy: Popup.NoAutoClose

    RestoreController {
        id: controller
        network: NetworkManager.network(navigation.param.network || '')
        mnemonic: (navigation.param.mnemonic || '').split(',')
        password: navigation.param.password || ''
        pin: navigation.param.pin || ''
        active: mnemonic.length === 24 || (mnemonic.length === 27 && password !== '')
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
                    navigation.go(`/${controller.network.id}/${controller.wallet.id}`)
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
        target: controller
        function onLoginError(error) {
            navigation.set({ mnemonic: undefined })
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
    }

    footer: DialogFooter {
        GButton {
            action: stack_layout.currentItem ? stack_layout.currentItem.backAction || null : null
            large: true
            visible: action
        }
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
            model: stack_layout.currentItem ? stack_layout.currentItem.actions || null : null
            GButton {
                action: modelData
                large: true
            }
        }
    }

    property bool closing: false
    onAboutToHide: closing = true
    contentItem: StackLayout {
        property Item currentItem: {
            if (stack_layout.currentIndex < 0) return null
            let item = stack_layout.children[stack_layout.currentIndex]
            if (item instanceof Loader) item = item.item
            if (item) item.focus = true
            return item
        }
        id: stack_layout
        Binding on currentIndex {
            when: !self.closing
            restoreMode: Binding.RestoreNone
            value: {
                let index = -1
                for (let i = 0; i < stack_layout.children.length; ++i) {
                    let child = stack_layout.children[i]
                    if (!(child instanceof Item)) continue
                    if (child.active) index = i
                }
                console.log('current index', index)
                return index
            }
        }
        SelectNetworkView {
            readonly property bool active: true
            showAMP: false
            view: 'restore'
        }
        AnimLoader {
            active: controller.network
            animated: self.opened
            sourceComponent: MnemonicEditor {
                // TODO: in order to go back activities must be removed
                // and session destroyed
                // readonly property Action backAction: Action {
                //     text: qsTrId('id_back')
                //     onTriggered: navigation.set({ network: undefined })
                // }
                id: editor
                enabled: !controller.active
                title: qsTrId('Insert your green mnemonic')
                actions: [
                    Action {
                        enabled: !controller.active
                        text: qsTrId('id_clear')
                        onTriggered: {
                            navigation.set({ mnemonic: undefined })
                            editor.controller.clear();
                        }
                    },
                    Action {
                        text: qsTrId('id_continue')
                        enabled: editor.valid && navigation.param.mnemonic === undefined
                        onTriggered: navigation.set({ mnemonic: editor.mnemonic })
                    }
                ]
            }
        }
        AnimLoader {
            active: controller.network && controller.mnemonic.length === 27
            animated: self.opened
            sourceComponent: ColumnLayout {
                readonly property Action backAction: Action {
                    text: qsTrId('id_back')
                    onTriggered: navigation.set({ mnemonic: undefined, password: undefined })
                }
                property list<Action> actions: [
                    Action {
                        id: passphrase_next_action
                        text: qsTrId('id_continue')
                        // enabled: !controller.active && controller.valid
                        onTriggered: navigation.set({ password: password_field.text })
                    }
                ]
                spacing: 16
                VSpacer {
                }
                Label {
                    Layout.alignment: Qt.AlignHCenter
                    text: qsTrId('id_please_provide_your_passphrase')
                    font.pixelSize: 20
                }
                TextField {
                    Layout.alignment: Qt.AlignHCenter
                    id: password_field
                    implicitWidth: 400
                    echoMode: TextField.Password
                    onAccepted: passphrase_next_action.trigger()
                    enabled: !controller.active
                    placeholderText: qsTrId('id_encryption_passphrase')
                }
                VSpacer {
                }
            }
        }
        AnimLoader {
            active: controller.wallet && controller.wallet.authenticated
            animated: self.opened
            sourceComponent: ColumnLayout {
                spacing: 16
                VSpacer {
                }
                Label {
                    Layout.alignment: Qt.AlignHCenter
                    text: qsTrId('id_set_a_new_pin')
                    font.pixelSize: 20
                }
                PinView {
                    Layout.alignment: Qt.AlignHCenter
                    id: pin_view
                    onPinChanged: {
                        if (!pin.valid) return
                        navigation.set({ pin: pin.value })
                        Qt.callLater(pin_view.clear)
                    }
                }
                VSpacer {
                }
            }
        }
        AnimLoader {
            active: controller.pin.length === 6
            animated: self.opened
            sourceComponent: ColumnLayout {
                readonly property Action backAction: Action {
                    text: qsTrId('id_back')
                    onTriggered: navigation.set({ pin: undefined })
                }
                spacing: 16
                VSpacer {
                }
                Label {
                    Layout.alignment: Qt.AlignHCenter
                    text: qsTrId('id_verify_your_pin')
                    font.pixelSize: 20
                }
                PinView {
                    Layout.alignment: Qt.AlignHCenter
                    onPinChanged: {
                        if (!pin.valid) return
                        if (pin.value !== controller.pin) {
                            clear();
                            ToolTip.show(qsTrId('id_pins_do_not_match_please_try'), 1000);
                        } else {
                            onTriggered: controller.accept()
                        }
                    }
                }
                VSpacer {
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
