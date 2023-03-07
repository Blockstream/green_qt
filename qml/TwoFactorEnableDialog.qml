import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "analytics.js" as AnalyticsJS

ControllerDialog {
    required property string method

    id: self
    title: qsTrId('id_set_up_twofactor_authentication')

    controller: TwoFactorController {
        id: controller
        context: self.context
        onFinished: self.accept()
    }

    AnalyticsView {
        active: self.visible
        name: 'WalletSettings2FASetup'
        segmentation: AnalyticsJS.segmentationSession(self.wallet)
    }

    AnimLoader {
        active: self.method !== 'gauth'
        animated: false
        sourceComponent: ColumnLayout {
            spacing: constants.s1
            Spacer {
            }
            Image {
                source: `qrc:/svg/2fa_${self.method}.svg`
                sourceSize.width: 64
                sourceSize.height: 64
                Layout.alignment: Qt.AlignHCenter
            }
            Label {
                id: description_text
                text: switch (self.method) {
                    case 'sms': return qsTrId('id_enter_phone_number')
                    case 'gauth': return qsTrId('id_scan_the_qr_code_in_google')
                    case 'email': return qsTrId('id_enter_your_email_address')
                    case 'phone': return qsTrId('id_enter_phone_number')
                    case 'telegram': return qsTrId('id_enter_telegram_username_or_number')
                }
                wrapMode: Text.WordWrap
                Layout.alignment: Qt.AlignHCenter
            }
            GTextField {
                id: data_field
                focus: true
                placeholderText: switch (self.method) {
                    case 'sms': case 'phone': return '+...'
                    case 'email': return '...@...'
                    case 'telegram': return '@...'
                    default: return ''
                }
                horizontalAlignment: TextInput.AlignHCenter
                selectByMouse: true
                onAccepted: change_action.trigger()
                onTextEdited: controller.clearErrors()
                Layout.fillWidth: true
                Layout.minimumWidth: 200
                Layout.alignment: Qt.AlignHCenter
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
            GButton {
                Layout.alignment: Qt.AlignHCenter
                action: Action {
                    id: change_action
                    enabled: data_field.text !== ''
                    onTriggered: controller.enable(self.method, data_field.text)
                }
                highlighted: true
                text: qsTrId('id_next')
            }
            VSpacer {
            }
        }
    }

    AnimLoader {
        active: self.method === 'gauth'
        animated: false
        sourceComponent: ColumnLayout {
            spacing: constants.s1
            Spacer {
            }
            RowLayout {
                spacing: constants.s1
                HSpacer {
                }
                Image {
                    source: `qrc:/svg/2fa_${self.method}.svg`
                    sourceSize.width: 32
                    sourceSize.height: 32
                }
                Label {
                    text: qsTrId('id_scan_the_qr_code_with_an')
                    wrapMode: Text.WordWrap
                }
                HSpacer {
                }
            }
            QRCode {
                Layout.fillWidth: true
                Layout.minimumHeight: 128
                text: {
                    const name = wallet.name
                    const label = name + ' @ Green ' + wallet.network.displayName
                    const secret = wallet.context.config[self.method].data.split('=')[1]
                    return 'otpauth://totp/' + escape(label) + '?secret=' + secret
                }
            }
            SectionLabel {
                Layout.alignment: Qt.AlignHCenter
                text: qsTrId('id_authenticator_secret_key')
            }
            CopyableLabel {
                Layout.alignment: Qt.AlignHCenter
                text: wallet.context.config[self.method].data.split('=')[1] || ''
            }
            GButton {
                Layout.alignment: Qt.AlignHCenter
                highlighted: true
                text: qsTrId('id_next')
                onClicked: controller.enable(self.method, wallet.context.config.telegram.data)
            }
            VSpacer {
            }
        }
    }
}
