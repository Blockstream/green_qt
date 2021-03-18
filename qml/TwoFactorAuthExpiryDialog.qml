import Blockstream.Green 0.1
import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12

ControllerDialog {
    id: dialog
    title: qsTrId('id_twofactor_authentication_expiry')
    doneText: qsTrId('id_twofactor_authentication_expiry')
    controller: Controller {
        wallet: dialog.wallet
    }

    component Option: DescriptiveRadioButton {
        required property int index
        readonly property int value: wallet.network.data.csv_buckets[index]
        checked: dialog.wallet.settings.csvtime === value
        enabled: true
        ButtonGroup.group: type_button_group
        Layout.fillWidth: true
    }

    initialItem: ColumnLayout {
        spacing: 16
        property list<Action> actions: [
            Action {
                text: qsTrId('id_next')
                enabled: type_button_group.checkedButton
                onTriggered: {
                    controller.setCsvTime(type_button_group.checkedButton.value)
                    dialog.doneText = qsTrId('id_twofactor_authentication_expiry') + " : " + type_button_group.checkedButton.text
                }
            }
        ]
        ButtonGroup {
            id: type_button_group
            exclusive: true
        }
        Option {
            index: 0
            text: qsTrId('id_6_months_25920_blocks')
            description: qsTrId('id_optimal_if_you_spend_coins')
        }
        Option {
            index: 1
            text: qsTrId('id_12_months_51840_blocks')
            description: qsTrId('id_wallet_coins_will_require')
        }
        Option {
            index: 2
            text: qsTrId('id_15_months_65535_blocks')
            description: qsTrId('id_optimal_if_you_rarely_spend')
        }
    }
}
