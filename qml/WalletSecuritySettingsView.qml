import Blockstream.Green 0.1
import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.5
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.12

ColumnLayout {
    id: self
    required property Wallet wallet

    spacing: 16

    Controller {
        id: controller
        wallet: self.wallet
    }

    SettingsBox {
        title: qsTrId('id_security')
        visible: !wallet.device && !self.wallet.network.electrum
        contentItem: RowLayout {
            Label {
                Layout.fillWidth: true
                text: qsTrId('id_disable_pin_access_for_this')
                wrapMode: Label.WordWrap
            }
            GButton {
                destructive: true
                Layout.alignment: Qt.AlignRight
                large: false
                text: qsTrId('id_disable_pin_access')
                onClicked: disable_all_pins_dialog.createObject(self).open()
            }
        }
    }

    SettingsBox {
        title: qsTrId('id_access')
        visible: !wallet.device
        contentItem: RowLayout {
            Label {
                text: qsTrId('id_enable_or_change_your_pin_to')
                wrapMode: Label.WordWrap
            }
            GButton {
                Layout.alignment: Qt.AlignRight
                large: false
                text: qsTrId('id_change_pin')
                onClicked: change_pin_dialog.createObject(Window.window).open()
            }
        }
    }

    SettingsBox {
        title: qsTrId('id_auto_logout_timeout')
        enabled: !wallet.locked
        visible: !wallet.device
        contentItem: RowLayout {
            Label {
                wrapMode: Label.WordWrap
                text: qsTrId('id_set_a_timeout_to_logout_after')
            }
            GComboBox {
                Layout.alignment: Qt.AlignRight
                model: [1, 2, 5, 10, 60]
                width: 200
                delegate: ItemDelegate {
                    width: parent.width
                    text: qsTrId('id_1d_minutes').arg(modelData)
                }
                displayText: qsTrId('id_1d_minutes').arg(currentText)
                onCurrentTextChanged: controller.changeSettings({ altimeout: model[currentIndex] })
                currentIndex: model.indexOf(wallet.settings.altimeout)
            }
        }
    }

    Component {
        id: disable_dialog
        TwoFactorDisableDialog {
            wallet: self.wallet
        }
    }

    Component {
        id: set_twofactor_threshold_dialog
        TwoFactorLimitDialog {
            wallet: self.wallet
        }
    }

    Component {
        id: two_factor_auth_expiry_dialog
        TwoFactorAuthExpiryDialog {
            wallet: self.wallet
        }
    }

    Component {
        id: change_pin_dialog
        ChangePinDialog {
            wallet: self.wallet
        }
    }

    Component {
        id: disable_all_pins_dialog
        DisableAllPinsDialog {
            wallet: self.wallet
        }
    }
}
