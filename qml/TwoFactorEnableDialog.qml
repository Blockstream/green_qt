import Blockstream.Green 0.1
import Blockstream.Green.Core 0.1
import QtQuick 2.13
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12

ControllerDialog {
    required property string method

    id: dialog
    title: qsTrId('id_set_up_twofactor_authentication')
    modal: true
    doneText: qsTrId('id_enabled')
    controller: Controller {
        wallet: dialog.wallet
    }
    initialItem: {
        if (method === 'gauth') return gauth_component
        // if (method === 'telegram') return telegram_component
        return generic_component
    }

    AnalyticsView {
        active: self.opened
        name: 'WalletSettings2FASetup'
        segmentation: segmentationSession(self.wallet)
    }

    Component {
        id: generic_component
        ColumnLayout {
            property list<Action> actions: [
                Action {
                    text: qsTrId('id_next')
                    enabled: data_field.text !== ''
                    onTriggered: controller.enableTwoFactor(method, data_field.text)
                }
            ]
            spacing: constants.s1
            Image {
                source: `qrc:/svg/2fa_${method}.svg`
                sourceSize.width: 64
                sourceSize.height: 64
                Layout.alignment: Qt.AlignHCenter
            }
            Label {
                id: description_text
                text: description
                wrapMode: Text.WordWrap
                Layout.alignment: Qt.AlignHCenter
            }
            GTextField {
                id: data_field
                placeholderText: placeholder
                selectByMouse: true
                Layout.fillWidth: true
                Layout.minimumWidth: 300
                Layout.alignment: Qt.AlignHCenter
            }
        }

    }

    Component {
        id: gauth_component
        ColumnLayout {
            property list<Action> actions: [
                Action {
                    text: qsTrId('id_next')
                    onTriggered: controller.enableTwoFactor(method, wallet.config[method].data)
                }
            ]
            spacing: constants.s1
            SectionLabel {
                text: qsTrId('id_authenticator_secret_key')
            }
            RowLayout {
                spacing: constants.s1
                Label {
                    id: secret_label
                    Layout.alignment: Qt.AlignHCenter
                    text: wallet.config[method].data.split('=')[1] || ''
                }
                ToolButton {
                    icon.source: 'qrc:/svg/copy.svg'
                    onClicked: {
                        Clipboard.copy(secret_label.text);
                        secret_label.ToolTip.show(qsTrId('id_copied_to_clipboard'), 1000);
                    }
                }
            }
            RowLayout {
                spacing: constants.s1
                Image {
                    source: `qrc:/svg/2fa_${method}.svg`
                    sourceSize.width: 32
                    sourceSize.height: 32
                }
                Label {
                    Layout.fillWidth: true
                    text: qsTrId('id_scan_the_qr_code_with_an')
                    wrapMode: Text.WordWrap
                }
            }
            HSpacer {
                height: 12
            }
            QRCode {
                Layout.fillWidth: true
                Layout.fillHeight: true
                text: {
                    const name = wallet.name
                    const label = name + ' @ Green ' + wallet.network.displayName
                    const secret = wallet.config[method].data.split('=')[1]
                    return 'otpauth://totp/' + escape(label) + '?secret=' + secret
                }
            }
        }
    }
}
