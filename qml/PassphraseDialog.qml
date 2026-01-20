import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import QtQuick.Window

Dialog {
    signal submit(string passphrase, bool always_ask)
    signal clear
    required property Wallet wallet
    property string passphrase: ''
    Overlay.modal: MultiEffect {
        anchors.fill: parent
        autoPaddingEnabled: false
        brightness: self.visible ? -0.05 : 0
        Behavior on brightness {
            NumberAnimation { duration: 200 }
        }
        blurEnabled: true
        blurMax: 64
        blur: self.visible ? 1 : 0
        Behavior on blur {
            NumberAnimation { duration: 200 }
        }
        source: ApplicationWindow.contentItem
    }
    id: self
    objectName: "PassphraseDialog"
    anchors.centerIn: parent
    closePolicy: Dialog.NoAutoClose
    leftPadding: 20
    topPadding: 20
    rightPadding: 20
    bottomPadding: 20
    background: Rectangle {
        color: '#232323'
        radius: 10
        border.width: 1
        border.color: Qt.alpha('#FFFFFF', 0.07)
    }
    Action {
        id: submit_action
        onTriggered: self.submit(passphrase_field.text, always_ask_switch.checked)
    }
    contentItem: StackViewPage {
        focus: true
        title: qsTrId('id_login_with_bip39_passphrase')
        rightItem: CloseButton {
            onClicked: self.reject()
        }
        contentItem: ColumnLayout {
            spacing: 20
            PasswordField {
                id: passphrase_field
                Layout.fillWidth: true
                focus: true
                text: self.passphrase
                onAccepted: submit_action.trigger()
            }
            GSwitch {
                Layout.alignment: Qt.AlignRight
                id: always_ask_switch
                text: qsTrId('id_always_ask')
                checked: self.wallet.login.passphrase ?? false
            }
            PrimaryButton {
                Layout.alignment: Qt.AlignCenter
                Layout.preferredWidth: 300
                text: qsTrId('id_submit')
                action: submit_action
            }
            LinkButton {
                Layout.alignment: Qt.AlignCenter
                text: qsTrId('id_clear')
                onClicked: self.clear()
            }
            Label {
                Layout.fillWidth: true
                Layout.topMargin: 40
                Layout.preferredWidth: 0
                color: '#9C9C9C'
                font.pixelSize: 14
                font.weight: 400
                horizontalAlignment: Label.AlignHCenter
                text: qsTrId('id_different_passphrases_generate')
                wrapMode: Label.WordWrap
            }
            LinkButton {
                Layout.alignment: Qt.AlignCenter
                text: qsTrId('id_learn_more')
                onClicked: Qt.openUrlExternally('https://help.blockstream.com/hc/en-us/articles/8712301763737-What-is-a-BIP39-passphrase')
            }
        }
    }
}
