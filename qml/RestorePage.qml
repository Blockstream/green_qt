import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

StackViewPage {
    id: self
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
            text: qsTrId('id_restore_green_wallet')
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
            Layout.topMargin: 20
            enable27: true
            size: controller.mnemonicSize
            onSizeClicked: (size) => controller.mnemonicSize = size
        }
        GridLayout {
            Layout.alignment: Qt.AlignCenter
            Layout.topMargin: 20
            Layout.bottomMargin: 20
            Layout.fillWidth: false
            columns: 3
            columnSpacing: 20
            rowSpacing: 10
            Repeater {
                model: controller.mnemonicSize
                WordField {
                    Layout.minimumWidth: 160
                    Layout.fillWidth: true
                    focus: index === 0
                    word: controller.words[index]
                }
            }
        }
        FieldTitle {
            Layout.alignment: Qt.AlignCenter
            visible: controller.mnemonicSize === 27
            text: qsTrId('id_please_provide_your_passphrase')
        }
        PasswordField {
            Layout.alignment: Qt.AlignCenter
            id: password_field
            implicitWidth: 400
            echoMode: TextField.Password
            visible: controller.mnemonicSize === 27
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
    footer: StackViewPage.Footer {
        contentItem: ColumnLayout {
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

    component PasswordField: TextField {
        id: self
        topPadding: 14
        bottomPadding: 13
        leftPadding: 15
        background: Rectangle {
            color: '#222226'
            radius: 5
            Rectangle {
                border.width: 2
                border.color: '#00B45A'
                color: 'transparent'
                radius: 9
                anchors.fill: parent
                anchors.margins: -4
                z: -1
                opacity: {
                    if (self.activeFocus) {
                        switch (self.focusReason) {
                        case Qt.TabFocusReason:
                        case Qt.BacktabFocusReason:
                        case Qt.ShortcutFocusReason:
                            return 1
                        }
                    }
                    return 0
                }
            }
        }
        font.family: 'SF Compact Display'
        font.pixelSize: 14
        font.weight: 457
    }
}
