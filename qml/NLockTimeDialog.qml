import Blockstream.Green
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ControllerDialog {
    required property Session session

    id: self
    title: qsTrId('id_set_timelock')
    controller: Controller {
        id: controller
        context: self.wallet
    }

    ColumnLayout {
        Label {
            text: qsTrId('id_redeem_your_deposited_funds')
        }
        Label {
            text: qsTrId('id_value_must_be_between_144_and')
        }
        RowLayout {
            Layout.alignment: Qt.AlignCenter
            GTextField {
                id: nlocktime_days
                text: Math.round(self.session.settings.nlocktime / 144 || 0)
                validator: IntValidator { bottom: 1; top: 200000 / 144; }
                onTextChanged: {
                    if (activeFocus) nlocktime_blocks.text = Math.round(text * 144);
                }
                horizontalAlignment: Qt.AlignRight
                Layout.alignment: Qt.AlignBaseline
            }
            Label {
                text: qsTrId('id_days') + ' ≈ '
                Layout.alignment: Qt.AlignBaseline
            }
            GTextField {
                id: nlocktime_blocks
                text: self.session.settings.nlocktime || 0
                validator: IntValidator { bottom: 144; top: 200000; }
                onTextChanged: {
                    if (activeFocus) nlocktime_days.text = Math.round(text / 144);
                }
                horizontalAlignment: Qt.AlignRight
                Layout.alignment: Qt.AlignBaseline
            }
            Label {
                text: qsTrId('id_blocks')
                Layout.alignment: Qt.AlignBaseline
            }
        }
        GButton {
            Layout.alignment: Qt.AlignRight
            text: qsTrId('id_ok')
            large: true
            highlighted: true
            enabled: nlocktime_blocks.acceptableInput
            onClicked: controller.changeSettings({ nlocktime: Number.parseInt(nlocktime_blocks.text) })
        }
    }
}
