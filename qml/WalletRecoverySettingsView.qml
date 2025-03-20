import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Effects
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts

import "analytics.js" as AnalyticsJS

ColumnLayout {
    required property Context context
    property bool showCredentials: false

    id: self
    spacing: 16

    AnalyticsView {
        active: true
        name: 'WalletSettingsRecovery'
        segmentation: AnalyticsJS.segmentationSession(Settings, self.context)
    }

    SettingsBox {
        title: qsTrId('id_recovery_phrase')
        visible: self.context.wallet.login instanceof PinData
        contentItem: ColumnLayout {
            spacing: 10
            Label {
                Layout.fillWidth: true
                text: qsTrId('id_the_recovery_phrase_can_be_used') + ' ' + qsTrId('id_blockstream_does_not_have')
                wrapMode: Text.WordWrap
            }
            MnemonicView {
                Layout.alignment: Qt.AlignCenter
                Layout.fillWidth: false
                Layout.topMargin: 10
                columns: self.context.mnemonic.length > 12 ? 4 : 2
                mnemonic: self.context.mnemonic
                layer.enabled: true
                layer.effect: MultiEffect {
                    autoPaddingEnabled: true
                    blurEnabled: true
                    blurMax: 64
                    blur: self.showCredentials ? 0 : 1
                    Behavior on blur {
                        NumberAnimation {
                            easing.type: Easing.OutCubic
                            duration: 300
                        }
                    }
                }
            }
            RowLayout {
                Layout.alignment: Qt.AlignCenter
                Layout.fillWidth: false
                Layout.topMargin: 10
                spacing: 20
                visible: self.context.credentials?.bip39_passphrase ?? false
                Image {
                    source: 'qrc:/svg2/passphrase.svg'
                }
                Label {
                    text: qsTrId('id_bip39_passphrase')
                }
                Label {
                    color: '#2FD058'
                    font.pixelSize : 14
                    font.weight: 600
                    text: self.context.credentials?.bip39_passphrase ?? ''
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        autoPaddingEnabled: true
                        blurEnabled: true
                        blurMax: 64
                        blur: self.showCredentials ? 0 : 1
                        Behavior on blur {
                            NumberAnimation {
                                easing.type: Easing.OutCubic
                                duration: 300
                            }
                        }
                    }
                }
            }
            Pane {
                id: tools_pane
                Layout.topMargin: 10
                Layout.alignment: Qt.AlignCenter
                padding: 12
                background: Rectangle {
                    border.width: 1
                    border.color: '#FFF'
                    color: 'transparent'
                    radius: height / 2
                    opacity: tools_pane.hovered ? 0.4 : 0
                    Behavior on opacity {
                        SmoothedAnimation {
                            velocity: 2
                        }
                    }
                }
                contentItem: RowLayout {
                    spacing: 20
                    CircleButton {
                        icon.source: self.showCredentials ? 'qrc:/svg2/eye_closed.svg' : 'qrc:/svg2/eye.svg'
                        onClicked: self.showCredentials = !self.showCredentials
                    }
                    CircleButton {
                        icon.source: 'qrc:/svg2/qrcode.svg'
                        onClicked: qrcode_popup.open()
                        QRCodePopup {
                            id: qrcode_popup
                            text: self.context.mnemonic.join(' ')
                        }
                    }
                }
            }
            Label {
                Layout.alignment: Qt.AlignCenter
                opacity: 0.6
                font.pixelSize: 12
                text: qsTrId('id_the_qr_code_does_not_include')
                visible: self.context.credentials?.bip39_passphrase ?? false
            }
        }
    }

    /*
    Loader {
        Layout.fillWidth: true
        active: !self.wallet.network.electrum && !wallet.network.liquid
        visible: active
        sourceComponent: SettingsBox {
            title: qsTrId('id_set_timelock')
            enabled: !!self.session.settings.notifications &&
                     !!self.session.settings.notifications.email_incoming &&
                     !!self.session.settings.notifications.email_outgoing
            contentItem: ColumnLayout {
                spacing: constants.s1
                Label {
                    Layout.fillWidth: true
                    text: qsTrId('id_redeem_your_deposited_funds') + '\n\n' + qsTrId('id_enable_email_notifications_to')
                    wrapMode: Text.WordWrap
                }
                GButton {
                    Layout.alignment: Qt.AlignRight
                    large: false
                    text: qsTrId('id_set_timelock')
                    onClicked: nlocktime_dialog.createObject(stack_view).open()
                }
            }
        }
    }

    Loader {
        Layout.fillWidth: true
        active: !self.wallet.network.electrum && !wallet.network.liquid
        visible: active
        sourceComponent: SettingsBox {
            title: qsTrId('id_set_an_email_for_recovery')
            contentItem: ColumnLayout {
                spacing: constants.s1
                Label {
                    Layout.fillWidth: true
                    text: qsTrId('id_set_up_an_email_to_get')
                    wrapMode: Text.WordWrap
                }
                Loader {
                    Layout.fillWidth: true
                    active: self.session.config?.email?.confirmed ?? false
                    visible: active
                    sourceComponent: RowLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: false
                        Label {
                            text: qsTrId('id_email')
                        }
                        HSpacer {
                        }
                        Label {
                            text: self.session.config?.email?.data ?? ''
                        }
                    }
                }
                GButton {
                    Layout.alignment: Qt.AlignRight
                    Component {
                        id: enable_dialog
                        SetRecoveryEmailDialog {
                            wallet: self.wallet
                        }
                    }
                    large: false
                    enabled: !(self.session.config?.email?.confirmed ?? false)
                    visible: enabled
                    text: qsTrId('id_enable')
                    onClicked: enable_dialog.createObject(stack_view).open()
                }
            }
        }
    }

    Loader {
        Layout.fillWidth: true
        active: !self.wallet.network.electrum
        visible: active
        sourceComponent: SettingsBox {
            title: qsTrId('id_delete_wallet')
            contentItem: ColumnLayout {
                spacing: constants.s1
                Label {
                    Layout.fillWidth: true
                    text: qsTrId('id_delete_permanently_your_wallet')
                    wrapMode: Text.WordWrap
                }
                Label {
                    Layout.fillWidth: true
                    visible: self.wallet.context.hasBalance
                    text: qsTrId('id_all_of_the_accounts_in_your')
                    wrapMode: Text.WordWrap
                }
                GButton {
                    Layout.alignment: Qt.AlignRight
                    large: false
                    destructive: true
                    enabled: !self.wallet.context.hasBalance
                    text: qsTrId('id_delete_wallet')
                    onClicked: delete_wallet_dialog.createObject(self).open()
                }
            }
        }
    }

    Component {
        id: nlocktime_dialog
        NLockTimeDialog {
            wallet: self.wallet
            session: self.session
        }
    }

    Component {
        id: delete_wallet_dialog
        DeleteWalletDialog {
            wallet: self.wallet
        }
    }
    */
}
