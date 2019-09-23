import Blockstream.Green 0.1
import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.5
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.12

Dialog {
    anchors.centerIn: Overlay.overlay
    modal: true
    parent: Overlay.overlay
    standardButtons: Dialog.Ok | Dialog.Cancel
    title: qsTr('RENAME ACCOUNT')

    onAccepted: controller.rename()
    onRejected: controller.reset()

    RenameAccountController {
        id: controller
        property alias name: name_field.text
    }

    SwipeView {
        anchors.fill: parent
        interactive: false

        GridLayout {
            columns: 2

            Label {
                text: qsTr('NAME')

                Layout.alignment: Qt.AlignRight
            }

            TextField {
                id: name_field
                text: account ? account.name : ''

                Layout.fillWidth: true
            }
        }
    }

}
