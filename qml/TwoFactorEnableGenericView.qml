import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "analytics.js" as AnalyticsJS

StackViewPage {
    signal next(string data)
    signal closed()
    required property Session session
    required property string method
    readonly property Wallet wallet: session.context.wallet
    id: self
    rightItem: CloseButton {
        onClicked: self.closed()
    }
    contentItem: ColumnLayout {
        spacing: 10
        Spacer {
        }
        MultiImage {
            Layout.alignment: Qt.AlignHCenter
            foreground: `qrc:/png/2fa_${self.method}.png`
            width: 280
            height: 160
        }
        Label {
            Layout.fillWidth: true
            Layout.preferredWidth: 0
            id: description_text
            font.pixelSize: 16
            font.weight: 600
            horizontalAlignment: Label.AlignHCenter
            text: switch (self.method) {
                case 'sms': return qsTrId('id_enter_phone_number')
                case 'gauth': return qsTrId('id_scan_the_qr_code_in_google')
                case 'email': return qsTrId('id_enter_your_email_address')
                case 'phone': return qsTrId('id_enter_phone_number')
                case 'telegram': return qsTrId('id_enter_telegram_username_or_number')
            }
            wrapMode: Text.WordWrap
        }
        TTextField {
            Layout.maximumWidth: 300
            id: data_field
            focus: true
            horizontalAlignment: TextInput.AlignHCenter
            selectByMouse: true
            onAccepted: change_action.trigger()
            onTextEdited: controller.clearErrors()
            Layout.fillWidth: true
            Layout.minimumWidth: 200
            Layout.alignment: Qt.AlignHCenter
        }
        Label {
            Layout.alignment: Qt.AlignCenter
            opacity: 0.6
            text: switch (self.method) {
                case 'sms': case 'phone': return '+...'
                case 'email': return '...@...'
                case 'telegram': return '@...'
                default: return ''
            }
            visible: false
            // TODO: show as placeholder
        }
        FixedErrorBadge {
            Layout.alignment: Qt.AlignHCenter
            error: controller.errors.data
        }
        FixedErrorBadge {
            Layout.alignment: Qt.AlignHCenter
            pointer: false
            error: controller.errors.code
        }
        PrimaryButton {
            Layout.alignment: Qt.AlignHCenter
            Layout.minimumWidth: 150
            Layout.topMargin: 15
            action: Action {
                id: change_action
                enabled: data_field.text !== ''
                onTriggered: self.next(data_field.text)
            }
            text: qsTrId('id_next')
        }
        VSpacer {
        }
    }
}
