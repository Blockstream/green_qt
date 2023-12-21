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
    MnemonicEditorController {
        id: controller
        mnemonicSize: 12
        passphrase: password_field.text
        onErrorsChanged: {
            if (errors.mnemonic === 'invalid') {
                self.failedRecoveryPhraseCheck()
            }
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
            text: self.wallet ? qsTrId('id_youll_need_your_recovery_phrase') : 'Make sure you got everything right'
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
            columns: ({ 12: 3, 24: 4, 27: 6 })[controller.mnemonicSize]
            columnSpacing: 20
            rowSpacing: 10
            Repeater {
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
        PrimaryButton {
            Layout.alignment: Qt.AlignCenter
            Layout.minimumWidth: 325
            Layout.topMargin: 20
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
