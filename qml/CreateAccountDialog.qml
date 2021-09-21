import Blockstream.Green 0.1
import Blockstream.Green.Core 0.1
import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.5
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.12
import QtMultimedia 5.13
import QtGraphicalEffects 1.15
import QtQuick.Shapes 1.0

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
                visible: !controller.wallet.network.electrum
                text: _labels['2of2_no_recovery']
                description: qsTrId('id_amp_accounts_are_only_available')
                enabled: wallet.network.liquid
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
                text: qsTrId('Hardware wallet')
                description: qsTrId('Use a hardware wallet to hold your 3rd recovery key.')
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
                    text: qsTrId('Coming Soon')
                    font.pixelSize: 10
                    font.styleName: 'Medium'
                    font.capitalization: Font.AllUppercase
                    parent: hww_card.contentItem
                }
            }
            Card {
                text: qsTrId('New Recovery Phrase')
                description: qsTrId('Generate a new recovery phrase to be used as your 3rd recovery key.')
                onClicked: {
                    dialog.controller.generateRecoveryMnemonic()
                    stack_view.push(generate_mnemonic_view)
                }
            }
            Card {
                text: qsTrId('More Options')
                description: qsTrId('Choose among advanced options for your 3rd recovery key.')
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
                    text: qsTrId('Generate')
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
                text: qsTrId('Existing Recovery Phrase')
                description: qsTrId('Use an existing recovery phrase as your 3rd recovery key.')
                onClicked: stack_view.push(edit_mnemonic_view)
            }
            Card {
                text: qsTrId('Extended Public Key')
                description: qsTrId('Use the xpub associated with an xpriv you want to use as your 3rd recovery key.')
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

    component BallonPath: ShapePath {
        startX: 16
        startY: 0
        PathAngleArc {
            moveToStart: false
            radiusX: 16
            radiusY: 16
            centerX: width - 16
            centerY: 16
            startAngle: -90
            sweepAngle: 90
        }
        PathAngleArc {
            moveToStart: false
            radiusX: 16
            radiusY: 16
            centerX: width - 16
            centerY: height - 16 - 8
            startAngle: 0
            sweepAngle: 90
        }
        PathLine {
            x: width / 2 + 8
            y: height - 8
        }
        PathLine {
            x: width / 2
            y: height
        }
        PathLine {
            x: width / 2 - 8
            y: height - 8
        }
        PathAngleArc {
            moveToStart: false
            radiusX: 16
            radiusY: 16
            centerX: 16
            centerY: height - 16 - 8
            startAngle: 90
            sweepAngle: 90
        }
        PathAngleArc {
            moveToStart: false
            radiusX: 16
            radiusY: 16
            centerX: 16
            centerY: 16
            startAngle: 180
            sweepAngle: 90
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
            background: null
            contentItem: ColumnLayout {
                spacing: 12
                SectionLabel {
                    text: qsTrId('Enter your xpub')
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
                        enabled: QtMultimedia.availableCameras.length > 0 && !scanner_popup.visible
                        icon.source: 'qrc:/svg/qr.svg'
                        icon.width: 16
                        icon.height: 16
                        onClicked: scanner_popup.open()
                        ToolTip.delay: Qt.styleHints.mousePressAndHoldInterval
                        ToolTip.text: qsTrId('id_scan_qr_code')
                        ToolTip.visible: hovered
                        Popup {
                            id: scanner_popup
                            background: MouseArea {
                                hoverEnabled: true
                            }
                            parent: xpub_field
                            x: parent.width / 2 - width / 2
                            y: -height
                            contentItem: Loader {
                                active: scanner_popup.visible
                                sourceComponent: Item {
                                    implicitWidth: 300
                                    implicitHeight: 200
                                    scale: scanner_popup.background.containsMouse ? 1.05 : (scanner_popup.visible ? 1 : 0)
                                    transformOrigin: Item.Bottom
                                    Behavior on scale {
                                        NumberAnimation {
                                            easing.type: Easing.OutBack
                                            duration: 400
                                        }
                                    }
                                    Shape {
                                        anchors.fill: parent
                                        BallonPath {
                                            strokeWidth: 0
                                            fillColor: constants.c800
                                        }
                                    }
                                    ScannerView {
                                        anchors.fill: parent
                                        id: scanner_view
                                        onCodeScanned: {
                                            xpub_field.text = code
                                            scanner_popup.close()
                                        }
                                        layer.enabled: true
                                        layer.effect: OpacityMask {
                                            maskSource: Shape {
                                                width: scanner_view.width
                                                height: scanner_view.height
                                                BallonPath {
                                                    strokeWidth: 1
                                                    strokeColor: 'transparent'
                                                    fillColor: 'white'
                                                }
                                            }
                                        }
                                    }
                                    Shape {
                                        anchors.fill: parent
                                        layer.samples: 4
                                        BallonPath {
                                            strokeColor: constants.g400
                                            strokeWidth: 1
                                            fillColor: 'transparent'
                                        }
                                    }
                                    ToolButton {
                                        anchors.top: parent.top
                                        anchors.right: parent.right
                                        anchors.margins: 8
                                        hoverEnabled: false
                                        flat: true
                                        icon.source: 'qrc:/svg/cancel.svg'
                                        icon.width: 16
                                        icon.height: 16
                                        onClicked: scanner_popup.close()
                                    }
                                }
                            }
                        }

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
                    error: dialog.controller.errors.recoveryXpub
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
                    error: dialog.controller.errors.name
                }
            }
        }
    }
}
