import Blockstream.Green 0.1
import QtQuick 2.14
import QtQml 2.14
import QtQuick.Controls 2.13
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.12

WizardPage {
    property alias valid: controller.valid
    property alias password: controller.password
    property alias mnemonic: controller.mnemonic
    property alias controller: controller
    property alias lengths: mnemonic_size_combobox.model
    property Component toolbar: ProgressBar {
        from: 0
        to: 1
        value: controller.progress
        Behavior on value {
            NumberAnimation {
                duration: 300
                easing.type: Easing.OutCubic
            }
        }
    }

    MnemonicEditorController {
        id: controller
        mnemonicSize: mnemonic_size_combobox.size
    }

    contentItem: ColumnLayout {
        spacing: 16
        VSpacer {
        }
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
            columns: 6
            Repeater {
                model: mnemonic_size_combobox.size
                WordField {
                    Layout.fillWidth: true
                    word: controller.words[index]
                }
            }
        }
        VSpacer {
        }
    }
}
