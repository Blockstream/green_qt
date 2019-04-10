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
    title: qsTr('CREATE ACCOUNT')

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
                text: qsTr('NAME')

                Layout.alignment: Qt.AlignRight
            }

            TextField {
                id: name_field

                Layout.fillWidth: true
            }

            Label {
                text: qsTr('TYPE')

                Layout.alignment: Qt.AlignRight
            }

            ComboBox {
                flat: true
                model: ['2 OF 2']

                Layout.fillWidth: true
            }
        }
    }
}
