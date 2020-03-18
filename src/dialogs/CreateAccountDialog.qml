import Blockstream.Green 0.1
import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.5
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.12
import '..'

WalletDialog {
    anchors.centerIn: Overlay.overlay
    modal: true
    parent: Overlay.overlay
    standardButtons: Dialog.Ok | Dialog.Cancel
    title: qsTr('id_add_new_account')
    width: 400

    onAccepted: controller.create()
    onClosed: controller.reset()

    property var xxx: wallet

    CreateAccountController {
        id: controller
        name: name_field.text
        wallet: xxx
    }

    SwipeView {
        anchors.fill: parent
        interactive: false

        GridLayout {
            columns: 2

            Label {
                text: qsTr('id_account_name')

                Layout.alignment: Qt.AlignRight
            }

            TextField {
                id: name_field

                Layout.fillWidth: true
            }

            Label {
                text: qsTr('id_account_type')

                Layout.alignment: Qt.AlignRight
            }

            ComboBox {
                flat: true
                model: [qsTr('id_standard_account')]

                Layout.fillWidth: true
            }
        }
    }
}
