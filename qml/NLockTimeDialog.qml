import Blockstream.Green 0.1
import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12

ControllerDialog {
    title: qsTrId('id_set_locktime')
    controller: SettingsController {}

    initialItem: ColumnLayout {
        property list<Action> actions: [
            Action {
                text: qsTrId('id_ok')
                enabled: nlocktime_blocks.acceptableInput
                onTriggered: controller.change({ nlocktime: Number.parseInt(nlocktime_blocks.text) })
            }
        ]
        Label {
            text: qsTrId('id_redeem_your_deposited_funds')
        }
        Label {
            text: qsTrId('id_value_must_be_between_144_and')
        }
        RowLayout {
            Layout.alignment: Qt.AlignCenter
            TextField {
                id: nlocktime_days
                text: Math.round(wallet.settings.nlocktime / 144 || 0)
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
            TextField {
                id: nlocktime_blocks
                text: wallet.settings.nlocktime || 0
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
    }
}
