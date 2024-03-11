import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

StackViewPage {
    signal mnemonicEntered(Wallet wallet, var mnemonic, string password)
    signal removeClicked()
    signal closeClicked()
    property Wallet wallet
    id: self
    title: self.wallet?.name ?? ''
    padding: 60
    StackView.onActivated: Analytics.recordEvent('wallet_restore')
    MnemonicEditorController {
        id: controller
        mnemonicSize: 12
        passphrase: password_field.text
        onErrorsChanged: {
            if (errors.mnemonic === 'invalid') {
                self.failedRecoveryPhraseCheck()
            }
        }
        onValidChanged: {
            if (controller.valid) restore_button.forceActiveFocus()
        }
        // onFailedRecoveryPhraseCheck: {
        //     Analytics.recordEvent('failed_recovery_phrase_check', {
        //         network: navigation.param.network === 'bitcoin' ? 'mainnet' : navigation.param.network
        //     })
        // }
    }
    rightItem: WalletOptionsButton {
        wallet: self.wallet
        onRemoveClicked: self.removeClicked()
        onCloseClicked: self.closeClicked()
    }
    contentItem: ColumnLayout {
        VSpacer {
        }
        Label {
            Layout.alignment: Qt.AlignCenter
            Layout.fillWidth: true
            Layout.preferredWidth: 0
            font.pixelSize: 26
            font.weight: 600
            horizontalAlignment: Label.AlignHCenter
            text: qsTrId('id_restore_green_wallet')
            visible: !self.wallet
            wrapMode: Label.WordWrap
        }
        Image {
            Layout.alignment: Qt.AlignCenter
            source: 'qrc:/svg2/warning.svg'
            visible: !!self.wallet
        }
        Label {
            Layout.alignment: Qt.AlignCenter
            font.pixelSize: 14
            font.weight: 500
            horizontalAlignment: Qt.AlignHCenter
            text: qsTrId('id_youve_entered_an_invalid_pin')
            visible: !!self.wallet
        }
        Label {
            Layout.alignment: Qt.AlignCenter
            Layout.fillWidth: true
            Layout.preferredWidth: 0
            font.pixelSize: 14
            font.weight: 400
            horizontalAlignment: Label.AlignHCenter
            opacity: 0.4
            text: self.wallet ? qsTrId('id_youll_need_your_recovery_phrase') : qsTrId('id_make_sure_you_got_everything')
            wrapMode: Label.Wrap
        }
        MnemonicSizeSelector {
            Layout.topMargin: 20
            enable27: true
            size: controller.mnemonicSize
            onSizeClicked: (size) => controller.mnemonicSize = size
        }
        GridLayout {
            Layout.alignment: Qt.AlignCenter
            Layout.topMargin: 20
            Layout.fillWidth: false
            columns: ({ 12: 3, 24: 6, 27: 6 })[controller.mnemonicSize]
            columnSpacing: 20
            rowSpacing: 10
            Repeater {
                id: word_field_repeater
                model: controller.mnemonicSize
                WordField {
                    Layout.minimumWidth: 140
                    Layout.fillWidth: true
                    focus: index === 0
                    word: controller.words[index]
                }
            }
        }
        FieldTitle {
            Layout.alignment: Qt.AlignCenter
            Layout.topMargin: 20
            visible: controller.mnemonicSize === 27
            text: qsTrId('id_please_provide_your_passphrase')
        }
        PasswordField {
            Layout.alignment: Qt.AlignCenter
            id: password_field
            implicitWidth: 400
            visible: controller.mnemonicSize === 27
        }
        FixedErrorBadge {
            Layout.alignment: Qt.AlignCenter
            Layout.topMargin: 20
            error: switch (controller.errors.mnemonic) {
                case 'invalid': return qsTrId('id_invalid_recovery_phrase')
            }
        }
        Pane {
            id: tools_pane
            Layout.topMargin: 10
            Layout.bottomMargin: 20
            Layout.alignment: Qt.AlignCenter
            padding: 12
            background: Rectangle {
                border.width: 1
                border.color: '#FFF'
                color: 'transparent'
                radius: height / 2
                opacity: tools_pane.hovered ? 0.4 : 0
                Behavior on opacity {
                    SmoothedAnimation {
                        velocity: 2
                    }
                }
            }
            contentItem: RowLayout {
                spacing: 20
                CircleButton {
                    icon.source: 'qrc:/svg2/x-circle.svg'
                    onClicked: controller.clear()
                }
                CircleButton {
                    Layout.alignment: Qt.AlignCenter
                    id: scanner_button
                    visible: scanner_popup.available
                    enabled: !scanner_popup.visible
                    icon.source: 'qrc:/svg2/qrcode.svg'
                    onClicked: {
                        scanner_button.forceActiveFocus()
                        scanner_popup.open()
                    }
                    ScannerPopup {
                        id: scanner_popup
                        onCodeScanned: (code) => {
                            controller.update(code)
                        }
                    }
                }
                CircleButton {
                    Layout.alignment: Qt.AlignCenter
                    icon.source: 'qrc:/svg2/paste.svg'
                    onClicked: {
                        word_field_repeater.itemAt(0).clear()
                        word_field_repeater.itemAt(0).paste()
                    }
                }
            }
        }

        PrimaryButton {
            Layout.alignment: Qt.AlignCenter
            Layout.minimumWidth: 325
            id: restore_button
            enabled: controller.valid
            text: qsTrId('id_restore')
            onClicked: self.mnemonicEntered(self.wallet, controller.mnemonic, controller.passphrase)
        }
        VSpacer {
        }
    }
    footerItem: ColumnLayout {
        Image {
            Layout.alignment: Qt.AlignCenter
            source: 'qrc:/svg2/house.svg'
        }
        Label {
            Layout.alignment: Qt.AlignCenter
            font.pixelSize: 12
            font.weight: 600
            text: qsTrId('id_make_sure_to_be_in_a_private')
        }
    }
}
