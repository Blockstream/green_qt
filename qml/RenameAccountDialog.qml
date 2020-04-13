import Blockstream.Green 0.1
import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.5
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.12

WalletDialog {
    property Account account
    modal: true
    standardButtons: Dialog.Ok | Dialog.Cancel
    title: qsTr('id_rename_account')

    onAccepted: controller.rename(name_field.text);
    onClosed: destroy()

    RenameAccountController {
        id: controller
    }

    ColumnLayout {
        SectionLabel {
            text: qsTr('id_name')
        }
        TextField {
            id: name_field
            text: account.name
            Layout.fillWidth: true
        }
    }
}
