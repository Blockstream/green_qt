import Blockstream.Green
import QtQuick
import QtQml
import QtQuick.Controls
import QtQuick.Layouts

WizardPage {
    property alias valid: controller.valid
    readonly property string password: mnemonic_size_combobox.size === 27 ? password_field.text : ''
    property alias mnemonic: controller.mnemonic
    property alias controller: controller
    property alias lengths: mnemonic_size_combobox.model

    signal failedRecoveryPhraseCheck()

    MnemonicEditorController {
        id: controller
        mnemonicSize: mnemonic_size_combobox.size
        passphrase: password_field.text
        onErrorsChanged: {
            if (errors.mnemonic === 'invalid') {
                self.failedRecoveryPhraseCheck()
            }
        }
    }

    id: self
    contentItem: ColumnLayout {
        spacing: 16
        RowLayout {
            Label {
                text: qsTrId('id_choose_recovery_phrase_length')
            }
            HSpacer {
            }
            GComboBox {
                Layout.minimumWidth: 120
                id: mnemonic_size_combobox
                property var sizes: [12, 24, 27]
                property real size: sizes[currentIndex]
                model: ["12 words", "24 words", "27 words"]
            }
        }
        GridLayout {
            columns: 3
            Repeater {
                model: mnemonic_size_combobox.size
                WordField {
                    focus: index === 0
                    Layout.fillWidth: true
                    word: controller.words[index]
                }
            }
        }
        RowLayout {
            visible: mnemonic_size_combobox.size === 27
            Label {
                text: qsTrId('id_please_provide_your_passphrase')
            }
            HSpacer {
            }
            GTextField {
                id: password_field
                implicitWidth: 400
                echoMode: TextField.Password
                placeholderText: qsTrId('id_encryption_passphrase')
            }
        }
        FixedErrorBadge {
            Layout.alignment: Qt.AlignCenter
            error: switch (controller.errors.mnemonic) {
                case 'invalid': return qsTrId('id_invalid_recovery_phrase')
            }
        }
        VSpacer {
        }
    }
}
