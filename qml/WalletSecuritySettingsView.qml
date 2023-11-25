import Blockstream.Green
import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    required property Wallet wallet
    required property Session session

    id: self

    spacing: 16

    Controller {
        id: controller
        context: self.wallet.context
    }

    SettingsBox {
        title: qsTrId('id_security')
        visible: !wallet.context.device && !self.wallet.network.electrum
        contentItem: RowLayout {
            spacing: constants.s1
            Label {
                Layout.fillWidth: true
                text: qsTrId('id_disable_pin_access_for_this')
                wrapMode: Text.WordWrap
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
        visible: !wallet.context.device
        contentItem: RowLayout {
            spacing: constants.s1
            Label {
                Layout.fillWidth: true
                text: qsTrId('id_enable_or_change_your_pin_to')
                wrapMode: Text.WordWrap
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
        visible: !wallet.context.device
        contentItem: RowLayout {
            spacing: constants.s1
            Label {
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                text: qsTrId('id_set_a_timeout_to_logout_after')
            }
            GComboBox {
                Layout.maximumWidth: 150
                Layout.alignment: Qt.AlignRight
                model: [1, 2, 5, 10, 60]
                width: 150
                delegate: ItemDelegate {
                    width: parent.width
                    text: qsTrId('id_1d_minutes').arg(modelData)
                }
                displayText: qsTrId('id_1d_minutes').arg(currentText)
                onCurrentTextChanged: controller.changeSettings({ altimeout: model[currentIndex] })
                currentIndex: model.indexOf(self.session.settings.altimeout)
            }
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
