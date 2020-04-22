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

    MnemonicEditorController {
        id: controller
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 32

        GridLayout {
            columns: 6

            Repeater {
                id: repeater
                model: 24

                WordField {
                    word: controller.words[index]
                }
            }
        }

        Page {
            Layout.alignment: Qt.AlignHCenter
            header: CheckBox {
                checked: controller.password
                text: qsTrId('id_password_protected')
                onCheckedChanged: controller.password = checked
            }

            RowLayout {
                visible: controller.password

                Repeater {
                    id: checksum
                    model: 3
                    WordField {
                        word: controller.words[index + 24]
                    }
                }
            }
        }
        RowLayout {
            Button {
                flat: true
                text: qsTrId('id_clear')
                onClicked: controller.clear()
            }
            Item {
                Layout.fillWidth: true
            }
            ProgressBar {
                from: 0
                to: 1
                value: controller.progress
                Behavior on value { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                Layout.fillWidth: true
            }
        }
    }
}
