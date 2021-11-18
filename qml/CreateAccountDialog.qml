import Blockstream.Green 0.1
import Blockstream.Green.Core 0.1
import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.5
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.12

ControllerDialog {
    id: dialog
    autoDestroy: true
    title: qsTrId('id_add_new_account')

    property var _labels: ({
        '2of2': qsTrId('id_standard_account'),
        '2of2_no_recovery': qsTrId('id_amp_account'),
        '2of3': qsTrId('id_2of3_account'),
        'p2wpkh': qsTrId('id_segwit_account'),
        'p2sh-p2wpkh': qsTrId('id_legacy_account')
    })

    function xPubError(error) {
        switch (error) {
            case 'empty': return qsTrId('id_empty')
            case 'invalid': return qsTrId('id_invalid_xpub')
            default: return ''
            }
    }

    controller: CreateAccountController {
        id: create_account_controller
        wallet: dialog.wallet
        onCreated: dialog.push(handler, doneComponent)
    }

    doneText: qsTrId('id_new_account_created')

    component Card: GCard {
        Layout.fillHeight: true
        Layout.maximumWidth: 300
    }

    initialItem: StackView {
        id: stack_view
        property var actions: currentItem.actions
        implicitHeight: currentItem.implicitHeight
        implicitWidth: currentItem.implicitWidth

        initialItem: RowLayout {
            spacing: 16
            Card {
                visible: !controller.wallet.network.electrum
                text: _labels['2of2']
                description: qsTrId('id_standard_accounts_allow_you_to')
                onClicked: {
                    create_account_controller.type = '2of2'
                    create_account_controller.name = _labels['2of2']
                    stack_view.push(finish_view)
                }
            }
            Card {
                visible: wallet.network.liquid && !controller.wallet.network.electrum
                text: _labels['2of2_no_recovery']
                description: qsTrId('id_amp_accounts_are_only_available')
                onClicked: {
                    create_account_controller.type = '2of2_no_recovery'
                    create_account_controller.name = _labels['2of2_no_recovery']
                    stack_view.push(finish_view)
                }
            }
            Card {
                text: _labels['2of3']
                description: qsTrId('id_a_2of3_account_requires_two_out')
                visible: !wallet.network.electrum && !wallet.network.liquid
                onClicked: {
                    create_account_controller.type = '2of3'
                    create_account_controller.name = _labels['2of3']
                    stack_view.push(basic_2of3_view)
                }
            }
            Card {
                visible: controller.wallet.network.electrum
                text: _labels['p2sh-p2wpkh']
                description: qsTrId('id_bip49_accounts_allow_you_to')
                onClicked: {
                    create_account_controller.type = 'p2sh-p2wpkh'
                    create_account_controller.name = _labels['p2sh-p2wpkh']
                    stack_view.push(finish_view)
                }
            }
            Card {
                visible: controller.wallet.network.electrum
                text: _labels['p2wpkh']
                description: qsTrId('id_bip84_accounts_allow_you_to')
                onClicked: {
                    create_account_controller.type = 'p2wpkh'
                    create_account_controller.name = _labels['p2wpkh']
                    stack_view.push(finish_view)
                }
            }
        }
    }

    Component {
        id: basic_2of3_view
        RowLayout {
            spacing: 16
            property list<Action> actions: [
                Action {
                    text: qsTrId('id_back')
                    onTriggered: stack_view.pop()
                }
            ]
            Card {
                id: hww_card
                enabled: false
                text: qsTrId('id_hardware_wallet')
                description: qsTrId('id_use_a_hardware_wallet_as_your')
                Label {
                    Layout.alignment: Qt.AlignCenter
                    background: Rectangle {
                        color: 'yellow'
                        radius: height / 2
                    }
                    color: 'black'
                    leftPadding: 8
                    rightPadding: 8
                    topPadding: 2
                    bottomPadding: 2
                    text: qsTrId('id_coming_soon')
                    font.pixelSize: 10
                    font.styleName: 'Medium'
                    font.capitalization: Font.AllUppercase
                    parent: hww_card.contentItem
                }
            }
            Card {
                text: qsTrId('id_new_recovery_phrase')
                description: qsTrId('id_generate_a_new_recovery_phrase')
                onClicked: {
                    dialog.controller.generateRecoveryMnemonic()
                    stack_view.push(generate_mnemonic_view)
                }
            }
            Card {
                text: qsTrId('id_more_options')
                description: qsTrId('id_advanced_options_for_your_third')
                onClicked: stack_view.push(advanced_view)
            }
        }
    }


    Component {
        id: generate_mnemonic_view
        MnemonicPage {
            property list<Action> actions: [
                Action {
                    text: qsTrId('id_back')
                    onTriggered: stack_view.pop()
                },
                Action {
                    text: qsTrId('id_generate')
                    onTriggered: dialog.controller.generateRecoveryMnemonic()
                },
                Action {
                    text: qsTrId('id_continue')
                    onTriggered: stack_view.push(backup_mnemonic_view)
                }
            ]
            mnemonic: dialog.controller.recoveryMnemonic
            onMnemonicSizeChanged: dialog.controller.recoveryMnemonicSize = mnemonicSize
        }
    }

    Component {
        id: backup_mnemonic_view
        MnemonicQuizPage {
            property list<Action> actions: [
                Action {
                    text: qsTrId('id_back')
                    onTriggered: stack_view.pop()
                }
            ]
            mnemonic: dialog.controller.recoveryMnemonic
            onCompleteChanged: {
                if (complete) stack_view.push(finish_view)
            }
        }
    }

    Component {
        id: advanced_view
        RowLayout {
            property list<Action> actions: [
                Action {
                    text: qsTrId('id_back')
                    onTriggered: stack_view.pop()
                }
            ]
            spacing: 16
            Card {
                text: qsTrId('id_existing_recovery_phrase')
                description: qsTrId('id_use_an_existing_recovery_phrase')
                onClicked: stack_view.push(edit_mnemonic_view)
            }
            Card {
                text: qsTrId('id_use_a_public_key')
                description: qsTrId('id_use_an_xpub_for_which_you_own')
                onClicked: stack_view.push(prompt_xpub_view)
            }
        }
    }

    Component {
        id: edit_mnemonic_view
        MnemonicEditor {
            id: editor
            property list<Action> actions: [
                Action {
                    text: qsTrId('id_back')
                    onTriggered: stack_view.pop()
                },
                Action {
                    text: qsTrId('id_next')
                    enabled: editor.valid
                    onTriggered: {
                        dialog.controller.recoveryMnemonic = editor.mnemonic
                        stack_view.push(finish_view)
                    }
                }
            ]
            lengths: ["12 words", "24 words"]
        }
    }

    Component {
        id: prompt_xpub_view
        GPane {
            id: self
            property list<Action> actions: [
                Action {
                    text: qsTrId('id_back')
                    onTriggered: stack_view.pop()
                },
                Action {
                    text: qsTrId('id_next')
                    enabled: dialog.controller.noErrors
                    onTriggered: stack_view.push(finish_view)
                }
            ]
            ScannerPopup {
                id: scanner_popup
                parent: xpub_field
                onCodeScanned: xpub_field.text = code
            }

            background: null
            contentItem: ColumnLayout {
                spacing: 12
                SectionLabel {
                    text: qsTrId('id_enter_your_xpub')
                }
                RowLayout {
                    GTextField {
                        Layout.fillWidth: true
                        id: xpub_field
                        focus: true
                        placeholderText: qsTrId('id_recovery_xpub')
                        Component.onCompleted: xpub_field.forceActiveFocus()
                        Layout.minimumWidth: 450
                        onTextChanged: dialog.controller.recoveryXpub = text
                        error: dialog.controller.errors.recoveryXpub
                    }
                    ToolButton {
                        enabled: scanner_popup.available && !scanner_popup.visible
                        icon.source: 'qrc:/svg/qr.svg'
                        icon.width: 16
                        icon.height: 16
                        onClicked: scanner_popup.open()
                        ToolTip.delay: Qt.styleHints.mousePressAndHoldInterval
                        ToolTip.text: qsTrId('id_scan_qr_code')
                        ToolTip.visible: hovered
                    }
                    ToolButton {
                        icon.source: 'qrc:/svg/paste.svg'
                        icon.width: 24
                        icon.height: 24
                        onClicked: {
                            xpub_field.clear();
                            xpub_field.paste();
                        }
                        ToolTip.delay: Qt.styleHints.mousePressAndHoldInterval
                        ToolTip.text: qsTrId('id_paste')
                        ToolTip.visible: hovered
                    }
                }
                FixedErrorBadge {
                    error: xPubError(dialog.controller.errors.recoveryXpub)
                }
            }
        }
    }
    Component {
        id: finish_view
        GPane {
            id: self
            property list<Action> actions: [
                Action {
                    text: qsTrId('id_back')
                    onTriggered: stack_view.pop()
                },
                Action {
                    text: qsTrId('id_create')
                    enabled: dialog.controller.noErrors
                    onTriggered: dialog.controller.create()
                }
            ]
            background: null
            padding: 0
            contentItem: ColumnLayout {
                spacing: 12
                SectionLabel {
                    text: qsTrId('id_account_type')
                }
                Label {
                    text: _labels[dialog.controller.type]
                }
                SectionLabel {
                    text: qsTrId('id_account_name')
                }
                GTextField {
                    Layout.fillWidth: true
                    text: dialog.controller.name
                    onTextChanged: dialog.controller.name = text
                    error: dialog.controller.errors.name
                }
                FixedErrorBadge {
                    error: xPubError(dialog.controller.errors.recoveryXpub)
                }
            }
        }
    }
}
