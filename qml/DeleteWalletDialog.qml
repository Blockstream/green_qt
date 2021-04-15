import Blockstream.Green 0.1
import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12

ControllerDialog {
    id: dialog
    title: qsTrId('Delete Wallet')
    controller: Controller {
        wallet: dialog.wallet
    }
    width: 400
    initialItem: ColumnLayout {
        property list<Action> actions: [
            Action {
                property bool destructive: true
                text: qsTrId('Delete wallet')
                enabled: confirm_checkbox.checked
                onTriggered: controller.deleteWallet()
            }
        ]
        Label {
            Layout.fillWidth: true
            text: qsTrId('This will log you out and delete this wallet from the app and the Blockstream servers database.')
            wrapMode: Label.WordWrap
        }
        CheckBox {
            Layout.fillWidth: true
            id: confirm_checkbox
            text: qsTrId('I confirm I want to delete this wallet')
        }
    }
}
