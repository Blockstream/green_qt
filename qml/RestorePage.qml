import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

StackViewPage {
    id: self
    background: Item {
        Image {
            anchors.fill: parent
            anchors.margins: -constants.p3
            source: 'qrc:/svg2/onboard_background.svg'
            fillMode: Image.PreserveAspectCrop
        }
    }
    contentItem: ColumnLayout {
        VSpacer {
        }
        Label {
            Layout.alignment: Qt.AlignCenter
            Layout.fillWidth: true
            Layout.preferredWidth: 0
            font.family: 'SF Compact Display'
            font.pixelSize: 26
            font.weight: 600
            horizontalAlignment: Label.AlignHCenter
            text: 'Restore Green Wallet'
            wrapMode: Label.WordWrap
        }
        Label {
            Layout.alignment: Qt.AlignCenter
            Layout.fillWidth: true
            Layout.preferredWidth: 0
            font.family: 'SF Compact Display'
            font.pixelSize: 14
            font.weight: 400
            horizontalAlignment: Label.AlignHCenter
            opacity: 0.4
            text: 'Make sure you got everything right'
            wrapMode: Label.Wrap
        }
        MnemonicSizeSelector {
            id: mnemonic_size_selector
            Layout.topMargin: 40
            Layout.bottomMargin: 50
            enable27: true
        }
        MnemonicEditorController {
            id: controller
            mnemonicSize: mnemonic_size_selector.size
            passphrase: password_field.text
            onErrorsChanged: {
                if (errors.mnemonic === 'invalid') {
                    self.failedRecoveryPhraseCheck()
                }
            }
        }
        GridLayout {
            Layout.alignment: Qt.AlignCenter
            Layout.fillWidth: false
            columns: 3
            columnSpacing: 20
            rowSpacing: 10
            Repeater {
                model: mnemonic_size_selector.size
                WordField {
                    Layout.minimumWidth: 160
                    Layout.fillWidth: true
                    focus: index === 0
                    word: controller.words[index]
                }
            }
        }
        RowLayout {
            visible: mnemonic_size_selector.size === 27
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
        //            onFailedRecoveryPhraseCheck: {
//                Analytics.recordEvent('failed_recovery_phrase_check', {
//                    network: navigation.param.network === 'bitcoin' ? 'mainnet' : navigation.param.network
//                })
//            }
        VSpacer {
        }
    }
    footer: ColumnLayout {
        Image {
            Layout.alignment: Qt.AlignCenter
            source: 'qrc:/svg2/house.svg'
        }
        Label {
            Layout.alignment: Qt.AlignCenter
            font.family: 'SF Compact Display'
            font.pixelSize: 12
            font.weight: 600
            text: qsTrId('id_make_sure_to_be_in_a_private')
        }
    }
}
