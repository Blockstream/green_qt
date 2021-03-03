import Blockstream.Green 0.1
import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.5
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.12

WalletDialog {
    id: dialog
    required property Account account
    title: qsTrId('id_rename_account')

    onAccepted: controller.rename(name_field.text)
    onClosed: destroy()

    RenameAccountController {
        id: controller
        account: dialog.account
    }
    footer: DialogFooter {
         HSpacer {}
         Button {
             flat: true
             text: qsTrId('id_cancel')
             onClicked: dialog.reject()
         }
         Button {
             flat: true
             text: qsTrId('id_ok')
             onClicked: dialog.accept()
         }
    }
    contentItem: ColumnLayout {
        SectionLabel {
            text: qsTrId('id_name')
        }
        TextField {
            Layout.minimumWidth: 400
            id: name_field
            text: account.name
            Layout.fillWidth: true
        }
    }
}
