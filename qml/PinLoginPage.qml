import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "analytics.js" as AnalyticsJS
import "util.js" as UtilJS

StackViewPage {
    signal loginFinished(Context context)
    signal restoreClicked()
    signal removeClicked()
    signal closeClicked()
    required property Wallet wallet
    StackView.onDeactivated: {
        pin_field.clear()
    }
    StackView.onActivating: {
        pin_field.clear()
        pin_field.enabled = true
        pin_field.forceActiveFocus()
    }
    id: self
    padding: 60
    title: self.wallet.name
    StackView.onActivated: {
        if (self.wallet.login.passphrase) {
            const dialog = passphrase_dialog.createObject(self)
            dialog.open()
        }
    }
    AnalyticsView {
        name: 'Login'
        active: UtilJS.effectiveVisible(self)
        segmentation: AnalyticsJS.segmentationSession(Settings, null)
    }
    LoginController {
        id: controller
        wallet: self.wallet
        onInvalidPin: {
            pin_field.clear()
            pin_field.enabled = self.wallet.login.attempts > 0
        }
        onLoginFinished: context => self.loginFinished(context)
        onLoginFailed: error => {
            error_badge.error = error
            pin_field.clear()
            pin_field.enabled = true
        }
    }
    leftItem: BackButton {
        text: qsTrId('id_wallets')
        onClicked: self.closeClicked()
        visible: WalletManager.wallets.length > 1
    }
    rightItem: WalletOptionsButton {
        wallet: self.wallet
        onPassphraseClicked: {
            const dialog = passphrase_dialog.createObject(self, { passphrase: controller.passphrase })
            dialog.open()
        }
        onRemoveClicked: self.removeClicked()
        onCloseClicked: self.closeClicked()
    }
    contentItem: GStackView {
        id: stack_view
        initialItem: ColumnLayout {
            Timer {
                interval: 2000
                running: self.wallet.login.attempts === 0
                onTriggered: stack_view.push(no_attempts_view)
            }
            Pane {
                Layout.alignment: Qt.AlignCenter
                padding: 20
                visible: controller.passphrase !== ''
                background: Rectangle {
                    color: '#222226'
                    radius: 5
                }
                contentItem: RowLayout {
                    spacing: 20
                    Image {
                        source: 'qrc:/svg2/passphrase.svg'
                    }
                    Label {
                        font.pixelSize: 14
                        font.weight: 600
                        text: qsTrId('id_bip39_passphrase_login')
                    }
                    CircleButton {
                        icon.source: 'qrc:/svg2/x-circle.svg'
                        onClicked: controller.passphrase = ''
                    }
                }
            }
            VSpacer {
            }
            Label {
                Layout.alignment: Qt.AlignCenter
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                font.pixelSize: 26
                font.weight: 600
                horizontalAlignment: Label.AlignHCenter
                text: qsTrId('id_enter_your_6digit_pin_to_access')
                wrapMode: Label.WordWrap
            }
            Label {
                Layout.alignment: Qt.AlignCenter
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                Layout.maximumWidth: 450
                font.pixelSize: 14
                font.weight: 400
                horizontalAlignment: Label.AlignHCenter
                opacity: 0.4
                text: qsTrId('id_youll_need_your_pin_to_log_in')
                wrapMode: Label.Wrap
            }
            PinField {
                Layout.alignment: Qt.AlignCenter
                Layout.topMargin: 36
                id: pin_field
                focus: true
                onPinEntered: (pin) => {
                    error_badge.clear()
                    pin_field.enabled = false
                    controller.loginWithPin(pin)
                }
            }
            FixedErrorBadge {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 20
                id: error_badge
                pointer: false
            }
            Label {
                Layout.alignment: Qt.AlignCenter
                Layout.bottomMargin: 30
                font.pixelSize: 12
                font.weight: 600
                horizontalAlignment: Qt.AlignHCenter
                text: {
                    switch (self.wallet.login.attempts) {
                    case 0: return qsTrId('id_no_attempts_remaining')
                    case 1: return qsTrId('id_last_attempt_if_failed_you_will')
                    case 2: return qsTrId('id_attempts_remaining_d').arg(self.wallet.login.attempts)
                    default: return ''
                    }
                }
                wrapMode: Label.WordWrap
            }
            PinPadButton {
                Layout.alignment: Qt.AlignCenter
                enabled: pin_field.enabled
                target: pin_field
            }
            VSpacer {
            }
        }
    }
    footerItem: ColumnLayout {
        Image {
            Layout.alignment: Qt.AlignCenter
            source: 'qrc:/svg2/house.svg'
        }
        Label {
            Layout.alignment: Qt.AlignCenter
            font.pixelSize: 12
            font.weight: 600
            text: qsTrId('id_make_sure_to_be_in_a_private')
        }
    }
    Component {
        id: no_attempts_view
        ColumnLayout {
            VSpacer {
            }
            Image {
                Layout.alignment: Qt.AlignCenter
                source: 'qrc:/svg2/warning.svg'
            }
            Label {
                Layout.alignment: Qt.AlignCenter
                Layout.bottomMargin: 45
                font.pixelSize: 14
                font.weight: 500
                horizontalAlignment: Qt.AlignHCenter
                text: qsTrId('id_youve_entered_an_invalid_pin')
            }
            PrimaryButton {
                Layout.alignment: Qt.AlignCenter
                text: qsTrId('id_restore_with_recovery_phrase')
                onClicked: self.restoreClicked()
            }
            VSpacer {
            }
        }
    }

    Component {
        id: passphrase_dialog
        PassphraseDialog {
            id: dialog
            wallet: self.wallet
            onClosed: dialog.destroy()
            onSubmit: (passphrase, always_ask) => {
                dialog.accept()
                self.wallet.login.passphrase = always_ask
                controller.passphrase = passphrase
                pin_field.forceActiveFocus()
            }
            onClear: {
                dialog.accept()
                self.wallet.login.passphrase = false
                controller.passphrase = ''
                pin_field.forceActiveFocus()
            }
        }
    }
}
