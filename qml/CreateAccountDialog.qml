import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

import "analytics.js" as AnalyticsJS

ControllerDialog {
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

    Navigation {
        id: navigation
    }

    Component.onCompleted: navigation.set({ view: 'type' })

    id: dialog
    autoDestroy: true
    title: qsTrId('id_add_new_account')
    controller: CreateAccountController {
        id: controller
        context: dialog.wallet.context
        name: navigation.param.name || null
        type: navigation.param.type || null
        recoveryMnemonic: navigation.param.mnemonic || []
        onCreated: {
            (account) => Analytics.recordEvent('account_create', AnalyticsJS.segmentationSubAccount(account))
        }
    }

    RowLayout {
        spacing: 16
        AnalyticsView {
            active: dialog.opened
            name: 'AddAccountChooseType'
            segmentation: AnalyticsJS.segmentationSession(dialog.wallet)
        }
        HSpacer {
        }
        Card {
            visible: !controller.context.network.electrum
            text: _labels['2of2']
            description: qsTrId('id_standard_accounts_allow_you_to')
            onClicked: navigation.set({ name: _labels['2of2'], type: '2of2', view: 'finish' })
        }
        Card {
            visible: controller.context.network.liquid && !controller.context.network.electrum
            text: _labels['2of2_no_recovery']
            description: qsTrId('id_amp_accounts_are_only_available')
            onClicked: navigation.set({ name: _labels['2of2_no_recovery'], type: '2of2_no_recovery', view: 'finish' })
        }
        Card {
            text: _labels['2of3']
            description: qsTrId('id_a_2of3_account_requires_two_out')
            visible: !controller.context.network.electrum && !controller.context.network.liquid
            onClicked: navigation.set({ name: _labels['2of3'], type: '2of3', view: '2of3' })
        }
        Card {
            visible: controller.context.network.electrum
            text: _labels['p2sh-p2wpkh']
            description: qsTrId('id_bip49_accounts_allow_you_to')
            onClicked: navigation.set({ name: _labels['p2sh-p2wpkh'], type: 'p2sh-p2wpkh', view: 'finish' })
        }
        Card {
            visible: controller.context.network.electrum
            text: _labels['p2wpkh']
            description: qsTrId('id_bip84_accounts_allow_you_to')
            onClicked: navigation.set({ name: _labels['p2wpkh'], type: 'p2wpkh', view: 'finish' })
        }
        HSpacer {
        }
    }

    component Card: GCard {
        Layout.fillHeight: true
        Layout.maximumWidth: 300
    }

    AnimLoader {
        active: controller.account
        animated: true
        sourceComponent: ColumnLayout {
            spacing: constants.p1
            VSpacer {}
            Image {
                Layout.alignment: Qt.AlignHCenter
                source: 'qrc:/svg/check.svg'
                sourceSize.width: 32
                sourceSize.height: 32
            }
            Label {
                Layout.alignment: Qt.AlignHCenter
                text: qsTrId('id_new_account_created')
            }
            GButton {
                Layout.alignment: Qt.AlignHCenter
                highlighted: true
                focus: true
                text: qsTrId('id_ok')
                onClicked: dialog.accept()
            }
            VSpacer {
            }
        }
    }



    AnimLoader {
        animated: true
        active: navigation.param.view === '2of3_generate'
        sourceComponent: ColumnLayout {
            MnemonicGenerator {
                id: generator
                size: mnemonic_page.mnemonicSize
            }
            RowLayout {
                HSpacer {
                }
                MnemonicPage {
                    id: mnemonic_page
                    mnemonic: generator.mnemonic
                }
                HSpacer {
                }
            }
            RowLayout {
                GButton {
                    text: qsTrId('id_back')
                    onClicked: navigation.pop()
                }
                HSpacer {
                }
                GButton {
                    text: qsTrId('id_generate')
                    onClicked: generator.generate()
                }
                GButton {
                    text: qsTrId('id_continue')
                    onClicked: navigation.set({ mnemonic: generator.mnemonic.join(' '), view: '2of3_backup' })
                }
            }
        }
    }

    AnimLoader {
        animated: true
        active: navigation.param.view === '2of3_backup'
        sourceComponent: ColumnLayout {
            RowLayout {
                HSpacer {
                }
                MnemonicQuizPage {
                    mnemonic: navigation.param.mnemonic.split(' ')
                    onCompleteChanged: navigation.set({ view: 'finish' })
                }
                HSpacer {
                }
            }
            RowLayout {
                GButton {
                    text: qsTrId('id_back')
                    onClicked: navigation.pop()
                }
                HSpacer {
                }
            }
            AnalyticsView {
                active: true
                name: 'RecoveryCheck'
                segmentation: AnalyticsJS.segmentationNetwork(controller.context.network)
            }
        }
    }

    AnimLoader {
        animated: true
        active: navigation.param.view === '2of3'
        sourceComponent: ColumnLayout {
            RowLayout {
                HSpacer {
                }
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
                        font.weight: 400
                        font.styleName: 'Regular'
                        font.capitalization: Font.AllUppercase
                        parent: hww_card.contentItem
                    }
                }
                Card {
                    text: qsTrId('id_new_recovery_phrase')
                    description: qsTrId('id_generate_a_new_recovery_phrase')
                    onClicked: navigation.set({ view: '2of3_generate' })
                }
                Card {
                    text: qsTrId('id_more_options')
                    description: qsTrId('id_advanced_options_for_your_third')
                    onClicked: navigation.set({ view: '2of3_advanced' })
                }
                HSpacer {
                }
            }
            RowLayout {
                GButton {
                    text: qsTrId('id_back')
                    onClicked: navigation.pop()
                }
                HSpacer {
                }
            }
        }
    }

    AnimLoader {
        animated: true
        active: navigation.param.view === '2of3_advanced'
        sourceComponent: ColumnLayout {
            RowLayout {
                HSpacer {
                }
                Card {
                    text: qsTrId('id_existing_recovery_phrase')
                    description: qsTrId('id_use_an_existing_recovery_phrase')
                    onClicked: navigation.set({ view: '2of3_mnemonic' })
                }
                Card {
                    text: qsTrId('id_use_a_public_key')
                    description: qsTrId('id_use_an_xpub_for_which_you_own')
                    onClicked: navigation.set({ view: '2of3_xpub' })
                }
                HSpacer {
                }
            }
            RowLayout {
                GButton {
                    text: qsTrId('id_back')
                    onClicked: navigation.pop()
                }
                HSpacer {
                }
            }
        }
    }

    AnimLoader {
        animated: true
        active: navigation.param.view === '2of3_mnemonic'
        sourceComponent: ColumnLayout {
            MnemonicEditor {
                id: editor
                lengths: ["12 words", "24 words"]
            }
            RowLayout {
                GButton {
                    text: qsTrId('id_back')
                    onClicked: navigation.pop()
                }
                HSpacer {
                }
                GButton {
                    text: qsTrId('id_next')
                    enabled: editor.valid
                    onClicked: navigation.set({ mnemonic: editor.mnemonic, view: 'finish' })
                }
            }
        }
    }

    AnimLoader {
        animated: true
        active: navigation.param.view === '2of3_xpub'
        sourceComponent: ColumnLayout {
            ScannerPopup {
                id: scanner_popup
                parent: xpub_field
                onCodeScanned: xpub_field.text = code
            }
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
                    onTextChanged: controller.recoveryXpub = text
                    error: controller.errors.recoveryXpub
                }
                ToolButton {
                    enabled: window.scannerAvailable && !scanner_popup.visible
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
                error: xPubError(controller.errors.recoveryXpub)
            }
            VSpacer {
            }
            RowLayout {
                GButton {
                    text: qsTrId('id_back')
                    onClicked: navigation.pop()
                }
                HSpacer {
                }
                GButton {
                    text: qsTrId('id_next')
                    enabled: controller.noErrors
                    onClicked: {
                        navigation.set({ xpub: xpub_field.text, view: 'finish' })
                    }
                }
            }
        }
    }

    AnimLoader {
        animated: true
        active: navigation.param.view === 'finish'
        sourceComponent: ColumnLayout {
            spacing: 12
            SectionLabel {
                text: qsTrId('id_account_type')
            }
            Label {
                text: _labels[navigation.param.type]
            }
            SectionLabel {
                text: qsTrId('id_account_name')
            }
            GTextField {
                Layout.fillWidth: true
                focus: true
                text: navigation.param.name
                onTextChanged: navigation.set({ name: text })
                error: controller.errors.name
            }
            FixedErrorBadge {
                Layout.alignment: Qt.AlignCenter
                error: xPubError(controller.errors.recoveryXpub)
            }
            FixedErrorBadge {
                Layout.alignment: Qt.AlignCenter
                error: controller.errors.create
            }
            VSpacer {
            }
            RowLayout {
                GButton {
                    text: qsTrId('id_back')
                    enabled: navigation.canPop
                    onClicked: navigation.pop()
                }
                HSpacer {
                }
                GButton {
                    text: qsTrId('id_create')
                    highlighted: true
                    enabled: controller.noErrors
                    onClicked: controller.create()
                }
            }
        }
    }
}
